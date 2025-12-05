/*
 * RISC-V WorldGuard CSR Definitions
 *
 * Based on RISC-V WorldGuard Specification v0.4
 * CSR addresses match QEMU implementation (sources/qemu/target/riscv/cpu_bits.h)
 */

#ifndef WORLDGUARD_H
#define WORLDGUARD_H

#include <stdint.h>

/* WorldGuard CSR addresses (from QEMU cpu_bits.h) */
#define CSR_MLWID       0x390   /* Machine Local World ID */
#define CSR_SLWID       0x190   /* Supervisor Local World ID */
#define CSR_MWIDDELEG   0x748   /* Machine WID Delegation */

/* Helper macros for CSR access */
#define csr_read(csr) ({                                    \
    unsigned long __v;                                      \
    __asm__ __volatile__ ("csrr %0, " #csr : "=r" (__v));   \
    __v;                                                    \
})

#define csr_write(csr, val) ({                              \
    unsigned long __v = (unsigned long)(val);               \
    __asm__ __volatile__ ("csrw " #csr ", %0" :: "r" (__v));\
})

#define csr_set(csr, val) ({                                \
    unsigned long __v = (unsigned long)(val);               \
    __asm__ __volatile__ ("csrs " #csr ", %0" :: "r" (__v));\
})

#define csr_clear(csr, val) ({                              \
    unsigned long __v = (unsigned long)(val);               \
    __asm__ __volatile__ ("csrc " #csr ", %0" :: "r" (__v));\
})

/* Generic CSR access by number */
static inline uint64_t read_csr_num(int csr_num)
{
    uint64_t val;
    switch (csr_num) {
        case CSR_MLWID:
            __asm__ __volatile__ ("csrr %0, 0x390" : "=r" (val));
            break;
        case CSR_SLWID:
            __asm__ __volatile__ ("csrr %0, 0x190" : "=r" (val));
            break;
        case CSR_MWIDDELEG:
            __asm__ __volatile__ ("csrr %0, 0x748" : "=r" (val));
            break;
        default:
            val = 0;
    }
    return val;
}

static inline void write_csr_num(int csr_num, uint64_t val)
{
    switch (csr_num) {
        case CSR_MLWID:
            __asm__ __volatile__ ("csrw 0x390, %0" :: "r" (val));
            break;
        case CSR_SLWID:
            __asm__ __volatile__ ("csrw 0x190, %0" :: "r" (val));
            break;
        case CSR_MWIDDELEG:
            __asm__ __volatile__ ("csrw 0x748, %0" :: "r" (val));
            break;
    }
}

/* WorldGuard World definitions */
#define WG_WORLD_0      0   /* Reserved/Boot */
#define WG_WORLD_1      1   /* U-mode */
#define WG_WORLD_2      2   /* S-mode */
#define WG_WORLD_3      3   /* M-mode/Trusted */

#endif /* WORLDGUARD_H */
