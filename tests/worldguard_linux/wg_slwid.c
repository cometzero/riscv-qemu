// SPDX-License-Identifier: GPL-2.0
/*
 * Minimal WorldGuard S-mode hook for Linux:
 * - Expose /proc/wg_slwid to read/write CSR 0x190 (slwid)
 * - Exercise WARL behavior via read-back
 */

/*
 * This file is built as a Linux kernel module. Some tooling (clangd) may not
 * have kernel headers/macros configured; provide minimal fallbacks so the file
 * stays parseable outside of a kernel build.
 */
#ifndef __KERNEL__
#include <stddef.h>
typedef long long loff_t;
typedef long ssize_t;
#ifndef __user
#define __user
#endif
#endif

#include <linux/init.h>
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/proc_fs.h>
#include <linux/seq_file.h>
#include <linux/uaccess.h>

#define WG_CSR_SLWID 0x190

static inline unsigned long wg_read_slwid(void)
{
    unsigned long v;
    asm volatile("csrr %0, 0x190" : "=r"(v));
    return v;
}

static inline void wg_write_slwid(unsigned long v)
{
    asm volatile("csrw 0x190, %0" :: "r"(v));
}

static int wg_slwid_show(struct seq_file *m, void *v)
{
    seq_printf(m, "%lu\n", wg_read_slwid());
    return 0;
}

static int wg_slwid_open(struct inode *inode, struct file *file)
{
    return single_open(file, wg_slwid_show, NULL);
}

static ssize_t wg_slwid_write(struct file *file, const char __user *buf,
                              size_t len, loff_t *ppos)
{
    char kbuf[32];
    unsigned long req, after;
    int ret;

    if (len == 0)
        return 0;

    if (len >= sizeof(kbuf))
        return -EINVAL;

    if (copy_from_user(kbuf, buf, len))
        return -EFAULT;

    kbuf[len] = '\0';

    ret = kstrtoul(kbuf, 0, &req);
    if (ret)
        return ret;

    wg_write_slwid(req);
    after = wg_read_slwid();

    pr_info("WGTEST: slwid write req=%lu readback=%lu\n", req, after);
    *ppos += len;
    return len;
}

static const struct proc_ops wg_slwid_proc_ops = {
    .proc_open = wg_slwid_open,
    .proc_read = seq_read,
    .proc_lseek = seq_lseek,
    .proc_release = single_release,
    .proc_write = wg_slwid_write,
};

static struct proc_dir_entry *wg_proc;

static int __init wg_slwid_init(void)
{
    unsigned long orig, v;

    wg_proc = proc_create("wg_slwid", 0666, NULL, &wg_slwid_proc_ops);
    if (!wg_proc)
        return -ENOMEM;

    orig = wg_read_slwid();
    pr_info("WGTEST: slwid initial=%lu\n", orig);

    /* Light self-test: write a few values and restore. */
    wg_write_slwid(2);
    v = wg_read_slwid();
    pr_info("WGTEST: slwid selftest write 2 -> %lu\n", v);

    wg_write_slwid(3);
    v = wg_read_slwid();
    pr_info("WGTEST: slwid selftest write 3 -> %lu\n", v);

    wg_write_slwid(orig);
    v = wg_read_slwid();
    pr_info("WGTEST: slwid restored=%lu\n", v);

    return 0;
}

static void __exit wg_slwid_exit(void)
{
    if (wg_proc)
        proc_remove(wg_proc);
}

module_init(wg_slwid_init);
module_exit(wg_slwid_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("riscv-qemu-bootflow");
MODULE_DESCRIPTION("WorldGuard S-mode slwid CSR control via /proc");
