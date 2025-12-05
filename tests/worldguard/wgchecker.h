/*
 * RISC-V WorldGuard Checker (wgChecker) Register Definitions
 *
 * Based on RISC-V WorldGuard Specification v0.4
 */

#ifndef WGCHECKER_H
#define WGCHECKER_H

#include <stdint.h>

/*
 * wgChecker MMIO Base Addresses (from QEMU virt machine)
 * These are the wgChecker control register bases, not protected regions
 */
#define WGC_DRAM_BASE   0x6000000UL  /* DRAM wgChecker MMIO */
#define WGC_FLASH_BASE  0x6001000UL  /* Flash wgChecker MMIO */
#define WGC_UART_BASE   0x6002000UL  /* UART wgChecker MMIO */

/*
 * wgChecker Register Offsets
 */
#define WGC_ERRCAUSE    0x000   /* Error Cause Register */
#define WGC_ERRADDR     0x008   /* Error Address Register */

/* Slot registers start at offset 0x100 */
#define WGC_SLOT_BASE   0x100
#define WGC_SLOT_SIZE   0x020   /* Size of each slot */

/* Slot register offsets within a slot */
#define WGC_SLOT_ADDR   0x000   /* Slot Address (64-bit) */
#define WGC_SLOT_PERM   0x008   /* Slot Permission (64-bit) */
#define WGC_SLOT_CFG    0x010   /* Slot Configuration (32-bit) */

/*
 * Slot Configuration (cfg) field values
 */
#define WGC_CFG_A_OFF       0   /* Slot disabled */
#define WGC_CFG_A_TOR       1   /* Top of Range */
#define WGC_CFG_A_NAPOT     3   /* Naturally Aligned Power-of-Two */

#define WGC_CFG_A_MASK      0x3
#define WGC_CFG_ER          (1 << 8)   /* Enable Read error report */
#define WGC_CFG_EW          (1 << 9)   /* Enable Write error report */
#define WGC_CFG_IR          (1 << 10)  /* Enable Read IRQ */
#define WGC_CFG_IW          (1 << 11)  /* Enable Write IRQ */
#define WGC_CFG_LOCK        (1 << 31)  /* Lock slot configuration */

/*
 * Permission bits (2 bits per World)
 * Format: [W3_W W3_R W2_W W2_R W1_W W1_R W0_W W0_R]
 */
#define WGC_PERM_R          0x1     /* Read permission */
#define WGC_PERM_W          0x2     /* Write permission */
#define WGC_PERM_RW         0x3     /* Read+Write permission */

/* Permission for specific World */
#define WGC_PERM(wid, perm) ((uint64_t)(perm) << (2 * (wid)))

/* Helper macros */
#define WGC_SLOT_ADDR_REG(base, slot)   ((base) + WGC_SLOT_BASE + (slot) * WGC_SLOT_SIZE + WGC_SLOT_ADDR)
#define WGC_SLOT_PERM_REG(base, slot)   ((base) + WGC_SLOT_BASE + (slot) * WGC_SLOT_SIZE + WGC_SLOT_PERM)
#define WGC_SLOT_CFG_REG(base, slot)    ((base) + WGC_SLOT_BASE + (slot) * WGC_SLOT_SIZE + WGC_SLOT_CFG)

/* Convert physical address to slot address format (addr >> 2) */
#define WGC_PA_TO_SLOT_ADDR(pa)    ((pa) >> 2)
#define WGC_SLOT_ADDR_TO_PA(sa)    ((sa) << 2)

/*
 * Error Cause Register bits
 */
#define WGC_ERRCAUSE_V          (1 << 0)    /* Valid */
#define WGC_ERRCAUSE_RW         (1 << 1)    /* 0=Read, 1=Write */
#define WGC_ERRCAUSE_WID_SHIFT  4
#define WGC_ERRCAUSE_WID_MASK   0xF0

/*
 * Inline functions for wgChecker access
 */
static inline void wgc_write32(uint64_t addr, uint32_t val)
{
    *(volatile uint32_t *)addr = val;
}

static inline uint32_t wgc_read32(uint64_t addr)
{
    return *(volatile uint32_t *)addr;
}

static inline void wgc_write64(uint64_t addr, uint64_t val)
{
    *(volatile uint64_t *)addr = val;
}

static inline uint64_t wgc_read64(uint64_t addr)
{
    return *(volatile uint64_t *)addr;
}

/* wgChecker slot access functions */
static inline uint64_t wgc_get_slot_addr(uint64_t wgc_base, int slot)
{
    return wgc_read64(WGC_SLOT_ADDR_REG(wgc_base, slot));
}

static inline void wgc_set_slot_addr(uint64_t wgc_base, int slot, uint64_t addr)
{
    wgc_write64(WGC_SLOT_ADDR_REG(wgc_base, slot), addr);
}

static inline uint64_t wgc_get_slot_perm(uint64_t wgc_base, int slot)
{
    return wgc_read64(WGC_SLOT_PERM_REG(wgc_base, slot));
}

static inline void wgc_set_slot_perm(uint64_t wgc_base, int slot, uint64_t perm)
{
    wgc_write64(WGC_SLOT_PERM_REG(wgc_base, slot), perm);
}

static inline uint32_t wgc_get_slot_cfg(uint64_t wgc_base, int slot)
{
    return wgc_read32(WGC_SLOT_CFG_REG(wgc_base, slot));
}

static inline void wgc_set_slot_cfg(uint64_t wgc_base, int slot, uint32_t cfg)
{
    wgc_write32(WGC_SLOT_CFG_REG(wgc_base, slot), cfg);
}

/* Error register access */
static inline uint64_t wgc_get_errcause(uint64_t wgc_base)
{
    return wgc_read64(wgc_base + WGC_ERRCAUSE);
}

static inline uint64_t wgc_get_erraddr(uint64_t wgc_base)
{
    return wgc_read64(wgc_base + WGC_ERRADDR);
}

static inline void wgc_clear_error(uint64_t wgc_base)
{
    wgc_write64(wgc_base + WGC_ERRCAUSE, 0);
}

#endif /* WGCHECKER_H */
