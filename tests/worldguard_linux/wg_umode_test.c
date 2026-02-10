// SPDX-License-Identifier: MIT
/*
 * WorldGuard U-mode test program.
 *
 * Requires:
 * - /proc/wg_slwid (provided by wg_slwid.ko)
 * - /dev/mem enabled
 * - reserved memory pages in DT (no-map):
 *     - shared page @ 0x90000000 (all worlds RW)
 *     - world2 page  @ 0xBFFF0000 (W2+W3+W0 RW, W1 denied)
 */

#include <errno.h>
#include <fcntl.h>
#include <inttypes.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

#define WGTEST_SH_PA 0x90000000ULL
#define WGTEST_W2_PA 0xBFFF0000ULL

#define PAT_SH 0xA5A5A5A5A5A5A5A5ULL

static int read_slwid(unsigned long *out)
{
    FILE *f = fopen("/proc/wg_slwid", "r");
    if (!f)
        return -1;

    if (fscanf(f, "%lu", out) != 1) {
        fclose(f);
        errno = EIO;
        return -1;
    }

    fclose(f);
    return 0;
}

static void *map_pa(int fd, uint64_t pa)
{
    void *p = mmap(NULL, 4096, PROT_READ | PROT_WRITE, MAP_SHARED, fd,
                   (off_t)pa);
    if (p == MAP_FAILED)
        return NULL;
    return p;
}

static int write_then_read64(volatile uint64_t *p, uint64_t v, uint64_t *out)
{
    *p = v;
    __sync_synchronize();
    *out = *p;
    __sync_synchronize();
    return 0;
}

static int check_read64(volatile uint64_t *p, uint64_t expect)
{
    uint64_t v = *p;
    __sync_synchronize();
    if (v != expect) {
        fprintf(stderr, "WGTEST: read mismatch got=0x%016" PRIx64
                        " expect=0x%016" PRIx64 "\n",
                v, expect);
        return -1;
    }
    return 0;
}

static int do_write_shared(int fd)
{
    void *m = map_pa(fd, WGTEST_SH_PA);
    uint64_t r;
    int rc = 0;

    if (!m) {
        perror("mmap shared");
        return 2;
    }

    if (write_then_read64((volatile uint64_t *)m, PAT_SH, &r) < 0 || r != PAT_SH) {
        fprintf(stderr, "WGTEST: write-shared failed readback=0x%016" PRIx64 "\n", r);
        rc = 1;
    } else {
        printf("WGTEST: write-shared ok\n");
    }

    munmap(m, 4096);
    return rc;
}

static int do_check_deny_w2(int fd)
{
    void *m = map_pa(fd, WGTEST_W2_PA);
    int rc;

    if (!m) {
        perror("mmap W2");
        return 2;
    }

    rc = check_read64((volatile uint64_t *)m, 0);
    if (rc == 0)
        printf("WGTEST: check-deny-w2 ok\n");

    munmap(m, 4096);
    return rc ? 1 : 0;
}

static void usage(const char *argv0)
{
    fprintf(stderr,
            "Usage: %s <write-shared|check-deny-w2>\n",
            argv0);
}

int main(int argc, char **argv)
{
    unsigned long slwid;
    int fd;

    if (argc != 2) {
        usage(argv[0]);
        return 2;
    }

    if (read_slwid(&slwid) < 0) {
        perror("read /proc/wg_slwid");
        return 2;
    }

    printf("WGTEST: slwid=%lu cmd=%s\n", slwid, argv[1]);

    fd = open("/dev/mem", O_RDWR | O_SYNC);
    if (fd < 0) {
        perror("open /dev/mem");
        return 2;
    }

    {
        int rc = 0;

        if (!strcmp(argv[1], "write-shared")) {
            rc = do_write_shared(fd);
        } else if (!strcmp(argv[1], "check-deny-w2")) {
            rc = do_check_deny_w2(fd);
        } else {
            usage(argv[0]);
            rc = 2;
        }

        close(fd);
        return rc;
    }

    /* Unreachable */
    return 2;
}
