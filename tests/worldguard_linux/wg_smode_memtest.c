// SPDX-License-Identifier: GPL-2.0
/*
 * WorldGuard S-mode memory enforcement test.
 *
 * Preconditions (this repo's WorldGuard virt DT + OpenSBI changes):
 * - OpenSBI writes patterns into:
 *     - W2 scratch @ 0xBFFF0000 (should be readable by S-mode WID=2)
 *     - W3 scratch @ 0xAFFF0000 (should be blocked for S-mode WID=2)
 * - Linux S-mode runs with mlwid=2.
 *
 * Expected behavior:
 * - Read W2 returns pattern
 * - Read W3 returns 0 (wgChecker blocked read)
 */

/* Tooling fallbacks for non-kernel parsers (clangd). */
#ifndef __KERNEL__
typedef unsigned long long u64;
#ifndef __iomem
#define __iomem
#endif
#endif

#include <linux/init.h>
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/io.h>

#define WGTEST_W2_PA 0xBFFF0000ULL
#define WGTEST_W3_PA 0xAFFF0000ULL

#define WGTEST_W2_VAL 0x1122334455667788ULL

static int __init wg_smode_memtest_init(void)
{
    void __iomem *w2;
    void __iomem *w3;
    u64 v2 = 0, v3 = 0;
    bool ok = true;

    pr_info("WGTEST: smode-memtest start\n");

    w2 = ioremap(WGTEST_W2_PA, 0x1000);
    if (!w2) {
        pr_err("WGTEST: FAIL (ioremap W2)\n");
        return -ENOMEM;
    }

    w3 = ioremap(WGTEST_W3_PA, 0x1000);
    if (!w3) {
        pr_err("WGTEST: FAIL (ioremap W3)\n");
        iounmap(w2);
        return -ENOMEM;
    }

    v2 = readq(w2);
    v3 = readq(w3);

    pr_info("WGTEST: W2 read @0x%llx = 0x%llx\n",
            (unsigned long long)WGTEST_W2_PA, (unsigned long long)v2);
    pr_info("WGTEST: W3 read @0x%llx = 0x%llx\n",
            (unsigned long long)WGTEST_W3_PA, (unsigned long long)v3);

    if (v2 != WGTEST_W2_VAL) {
        pr_err("WGTEST: FAIL (W2 expected 0x%llx)\n",
               (unsigned long long)WGTEST_W2_VAL);
        ok = false;
    }

    if (v3 != 0) {
        pr_err("WGTEST: FAIL (W3 expected 0x0 due to WG block)\n");
        ok = false;
    }

    if (ok)
        pr_info("WGTEST: PASS\n");
    else
        pr_info("WGTEST: FAIL\n");

    iounmap(w3);
    iounmap(w2);
    return 0;
}

static void __exit wg_smode_memtest_exit(void)
{
}

module_init(wg_smode_memtest_init);
module_exit(wg_smode_memtest_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("riscv-qemu-bootflow");
MODULE_DESCRIPTION("WorldGuard S-mode memory enforcement test");
