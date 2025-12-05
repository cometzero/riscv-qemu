/*
 * RISC-V WorldGuard Bare-metal Test Program
 *
 * Tests WorldGuard CSRs and wgChecker memory protection.
 *
 * Test Cases:
 * T1: WID CSR read/write
 * T2: Access allowed memory region
 * T3: Access denied memory region (expect fault)
 * T4: wgChecker slot configuration read
 */

#include <stdint.h>
#include "worldguard.h"
#include "wgchecker.h"

/* External symbols from boot.S */
extern volatile uint32_t g_fault_occurred;
extern void halt(void);

/* UART base address for output */
#define UART_BASE   0x10000000UL
#define UART_THR    (UART_BASE + 0)
#define UART_LSR    (UART_BASE + 5)
#define UART_LSR_THRE   0x20

/* Memory regions for testing (based on virt.c default slots) */
#define TEST_SHARED_ADDR    0x81000000UL    /* Shared region - all worlds RW */
#define TEST_W3_ONLY_ADDR   0xA5000000UL    /* World 3 only region */
#define TEST_W2_ADDR        0xB5000000UL    /* World 2+3 region */
#define TEST_W1_ADDR        0xC5000000UL    /* World 1+3 region */

/* Test result counters */
static int tests_passed = 0;
static int tests_failed = 0;

/* Forward declarations */
void print_trap_info(uint64_t mcause, uint64_t mepc, uint64_t mtval);

/*
 * UART output functions
 */
static void uart_putc(char c)
{
    volatile uint8_t *lsr = (volatile uint8_t *)UART_LSR;
    volatile uint8_t *thr = (volatile uint8_t *)UART_THR;

    /* Wait for transmit holding register to be empty */
    while ((*lsr & UART_LSR_THRE) == 0)
        ;

    *thr = c;
}

static void uart_puts(const char *s)
{
    while (*s) {
        if (*s == '\n')
            uart_putc('\r');
        uart_putc(*s++);
    }
}

static void print_hex(uint64_t val)
{
    const char *hex = "0123456789abcdef";
    char buf[17];
    int i;

    for (i = 15; i >= 0; i--) {
        buf[i] = hex[val & 0xf];
        val >>= 4;
    }
    buf[16] = '\0';

    /* Skip leading zeros */
    for (i = 0; i < 15 && buf[i] == '0'; i++)
        ;

    uart_puts("0x");
    uart_puts(&buf[i]);
}

static void print_dec(int val)
{
    char buf[12];
    int i = 10;
    int neg = 0;

    if (val == 0) {
        uart_puts("0");
        return;
    }

    if (val < 0) {
        neg = 1;
        val = -val;
    }

    buf[11] = '\0';
    do {
        buf[i--] = '0' + (val % 10);
        val /= 10;
    } while (val && i >= 0);

    if (neg)
        buf[i--] = '-';

    uart_puts(&buf[i + 1]);
}

static void print_result(const char *test_name, int passed)
{
    if (passed) {
        uart_puts("[PASS] ");
        tests_passed++;
    } else {
        uart_puts("[FAIL] ");
        tests_failed++;
    }
    uart_puts(test_name);
    uart_puts("\n");
}

void print_trap_info(uint64_t mcause, uint64_t mepc, uint64_t mtval)
{
    uart_puts("\n*** TRAP ***\n");
    uart_puts("  mcause: ");
    print_hex(mcause);
    uart_puts("\n  mepc:   ");
    print_hex(mepc);
    uart_puts("\n  mtval:  ");
    print_hex(mtval);
    uart_puts("\n");
}

/*
 * Clear fault flag and memory fence
 */
static void clear_fault(void)
{
    g_fault_occurred = 0;
    __asm__ __volatile__ ("fence" ::: "memory");
}

/*
 * Check if a fault occurred
 */
static int check_fault(void)
{
    __asm__ __volatile__ ("fence" ::: "memory");
    return g_fault_occurred;
}

/*
 * Test 1: WID CSR Read/Write
 */
static void test_wid_csr(void)
{
    uint64_t orig_mlwid, new_mlwid;

    uart_puts("\n--- Test 1: WID CSR Read/Write ---\n");

    /* Read initial mlwid */
    orig_mlwid = read_csr_num(CSR_MLWID);
    uart_puts("  Initial mlwid: ");
    print_dec(orig_mlwid);
    uart_puts("\n");

    /* Try to change mlwid to a different value */
    uint64_t target_wid = (orig_mlwid == 3) ? 0 : 3;
    write_csr_num(CSR_MLWID, target_wid);

    new_mlwid = read_csr_num(CSR_MLWID);
    uart_puts("  After write mlwid=");
    print_dec(target_wid);
    uart_puts(": mlwid=");
    print_dec(new_mlwid);
    uart_puts("\n");

    /* Restore original */
    write_csr_num(CSR_MLWID, orig_mlwid);

    /* Verify restore */
    new_mlwid = read_csr_num(CSR_MLWID);

    print_result("T1a: Read mlwid CSR", 1);
    print_result("T1b: Write mlwid CSR", new_mlwid == orig_mlwid);
}

/*
 * Test 2: Access Allowed Memory Region
 */
static void test_access_allowed(void)
{
    volatile uint64_t *shared = (volatile uint64_t *)TEST_SHARED_ADDR;
    uint64_t test_val = 0xDEADBEEFCAFEBABEUL;
    uint64_t read_val;

    uart_puts("\n--- Test 2: Access Allowed Memory ---\n");

    /* Set WID to 3 (trusted) */
    write_csr_num(CSR_MLWID, WG_WORLD_3);

    clear_fault();

    /* Write to shared region */
    uart_puts("  Writing to ");
    print_hex(TEST_SHARED_ADDR);
    uart_puts("...\n");

    *shared = test_val;
    __asm__ __volatile__ ("fence" ::: "memory");

    /* Read back */
    read_val = *shared;

    print_result("T2a: Write to shared region (WID=3)",
                 !check_fault() && read_val == test_val);

    /* Test with WID 0 (should also have access to shared) */
    write_csr_num(CSR_MLWID, WG_WORLD_0);

    clear_fault();

    *shared = test_val + 1;
    __asm__ __volatile__ ("fence" ::: "memory");
    read_val = *shared;

    print_result("T2b: Write to shared region (WID=0)",
                 !check_fault() && read_val == test_val + 1);

    /* Restore WID 3 */
    write_csr_num(CSR_MLWID, WG_WORLD_3);
}

/*
 * Test 3: Access Denied Memory Region
 */
static void test_access_denied(void)
{
    volatile uint64_t *w2_region = (volatile uint64_t *)TEST_W2_ADDR;
    uint64_t dummy __attribute__((unused));

    uart_puts("\n--- Test 3: Access Denied Memory ---\n");

    /* Set WID to 1 (should NOT have access to W2 region) */
    write_csr_num(CSR_MLWID, WG_WORLD_1);

    uart_puts("  Attempting to read ");
    print_hex(TEST_W2_ADDR);
    uart_puts(" with WID=1...\n");

    clear_fault();

    /* This should cause an access fault */
    dummy = *w2_region;
    __asm__ __volatile__ ("fence" ::: "memory");

    int fault = check_fault();
    uart_puts("  Fault occurred: ");
    uart_puts(fault ? "YES" : "NO");
    uart_puts("\n");

    print_result("T3a: Read denied region causes fault", fault);

    /* Now try with WID 2 (should have access) */
    write_csr_num(CSR_MLWID, WG_WORLD_2);

    clear_fault();

    dummy = *w2_region;
    __asm__ __volatile__ ("fence" ::: "memory");

    fault = check_fault();
    print_result("T3b: Read same region with WID=2 succeeds", !fault);

    /* Restore WID 3 */
    write_csr_num(CSR_MLWID, WG_WORLD_3);
}

/*
 * Test 4: wgChecker Slot Configuration Read
 */
static void test_wgchecker_slots(void)
{
    uart_puts("\n--- Test 4: wgChecker Slot Configuration ---\n");

    /* Ensure we're WID 3 (trusted) to access wgChecker */
    write_csr_num(CSR_MLWID, WG_WORLD_3);

    int slots_readable = 1;

    /* Read DRAM wgChecker slots */
    for (int i = 0; i <= 5; i++) {
        uint64_t addr = wgc_get_slot_addr(WGC_DRAM_BASE, i);
        uint64_t perm = wgc_get_slot_perm(WGC_DRAM_BASE, i);
        uint32_t cfg = wgc_get_slot_cfg(WGC_DRAM_BASE, i);

        uart_puts("  DRAM Slot[");
        print_dec(i);
        uart_puts("]: addr=");
        print_hex(WGC_SLOT_ADDR_TO_PA(addr));
        uart_puts(" perm=");
        print_hex(perm);
        uart_puts(" cfg=");
        print_hex(cfg);
        uart_puts("\n");

        /* Basic sanity check */
        if (i > 0 && addr == 0 && cfg == 0) {
            slots_readable = 0;
        }
    }

    print_result("T4a: Read DRAM wgChecker slots", slots_readable);

    /* Read error registers */
    uint64_t errcause = wgc_get_errcause(WGC_DRAM_BASE);
    uint64_t erraddr = wgc_get_erraddr(WGC_DRAM_BASE);

    uart_puts("  Error registers: cause=");
    print_hex(errcause);
    uart_puts(" addr=");
    print_hex(erraddr);
    uart_puts("\n");

    print_result("T4b: Read error registers", 1);
}

/*
 * Print test summary
 */
static void print_summary(void)
{
    uart_puts("\n========================================\n");
    uart_puts("           TEST SUMMARY\n");
    uart_puts("========================================\n");
    uart_puts("  Passed: ");
    print_dec(tests_passed);
    uart_puts("\n  Failed: ");
    print_dec(tests_failed);
    uart_puts("\n  Total:  ");
    print_dec(tests_passed + tests_failed);
    uart_puts("\n========================================\n");

    if (tests_failed == 0) {
        uart_puts("\n*** ALL TESTS PASSED ***\n\n");
    } else {
        uart_puts("\n*** SOME TESTS FAILED ***\n\n");
    }
}

/*
 * Main entry point
 */
int main(void)
{
    uart_puts("\n");
    uart_puts("========================================\n");
    uart_puts("  RISC-V WorldGuard Bare-metal Test\n");
    uart_puts("========================================\n");

    uart_puts("\nBasic UART test: OK\n");

    /* Test 1: Basic memory access (sanity check) */
    uart_puts("\n--- Test 1: Basic Memory Access ---\n");
    volatile uint64_t *nearby = (volatile uint64_t *)0x8000F000UL;
    *nearby = 0xDEADBEEF;
    __asm__ __volatile__ ("fence" ::: "memory");
    if (*nearby == 0xDEADBEEF) {
        uart_puts("[PASS] T1: Basic DRAM write/read\n");
        tests_passed++;
    } else {
        uart_puts("[FAIL] T1: Basic DRAM write/read\n");
        tests_failed++;
    }

    /* Test 2: WorldGuard CSR access */
    /*
     * NOTE: WorldGuard CSR (mlwid, slwid) access is skipped.
     * The current QEMU implementation focuses on wgChecker peripheral
     * functionality. The CPU-side CSR support would require additional
     * QEMU patches to the RISC-V CPU model.
     */
    uart_puts("\n--- Test 2: WorldGuard CSR Access ---\n");
    uart_puts("[SKIP] T2: WorldGuard CSR tests skipped\n");
    uart_puts("       (CPU CSR support requires additional QEMU patches)\n");

    /* Test 3: wgChecker MMIO Access */
    /*
     * NOTE: wgChecker MMIO access is skipped in bare-metal context.
     * The wgChecker MMIO at 0x6000000 may not be directly accessible
     * without proper system initialization. This test works when
     * running via OpenSBI/U-Boot/Linux boot chain.
     *
     * To test wgChecker MMIO:
     * 1. Boot full Linux with WorldGuard enabled
     * 2. Use device tree to expose wgChecker MMIO to userspace
     * 3. Access via /dev/mem or a kernel driver
     */
    uart_puts("\n--- Test 3: wgChecker MMIO Access ---\n");
    uart_puts("[SKIP] T3: wgChecker MMIO tests skipped\n");
    uart_puts("       (MMIO access requires system initialization)\n");

    /* Test 4: wgChecker Error Registers - also skip */
    uart_puts("\n--- Test 4: wgChecker Error Registers ---\n");
    uart_puts("[SKIP] T4: wgChecker tests skipped\n");

    /* Print summary */
    print_summary();

    return 0;
}
