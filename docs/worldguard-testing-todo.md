# WorldGuard Testing TODO

This document outlines the remaining tasks for comprehensive WorldGuard testing.

## Completed ✅

### 1. QEMU Default wgChecker Configuration

DRAM wgChecker is configured with default slots when `wg-hwbypass=off`:

| Slot | Address Range | Access |
|------|--------------|--------|
| 1 | 0x80000000 - 0x9FFFFFFF (512MB) | All worlds RW (shared) |
| 2 | 0xA0000000 - 0xAFFFFFFF (256MB) | W0+W3 (boot+trusted) |
| 3 | 0xB0000000 - 0xBFFFFFFF (256MB) | W0+W2+W3 |
| 4 | 0xC0000000 - 0xCFFFFFFF (256MB) | W0+W1+W3 |
| 5 | 0xD0000000 - 0xFFFFFFFF (remainder) | W0+W3 |

### 2. Bare-metal Test Framework

Created `tests/worldguard/` with CSR/MMIO definitions and test infrastructure.
Note: CSR tests are skipped in bare-metal mode due to QEMU initialization timing.

### 3. Full Boot Chain Verification

Successfully verified OpenSBI → U-Boot → Linux → Buildroot boot with `hwbypass=off`.

---

## TODO: OpenSBI WorldGuard Patch

### Overview

OpenSBI needs to be modified to properly initialize and manage WorldGuard features.
This enables dynamic WID management during boot and provides SBI calls for S-mode.

### Prerequisites

- QEMU with WorldGuard patches (completed)
- Understanding of OpenSBI internals
- RISC-V WorldGuard Specification v0.4

### Implementation Plan

#### Phase 1: CSR Definitions and Detection

**File: `include/sbi/riscv_encoding.h`**

Add WorldGuard CSR definitions:
```c
/* WorldGuard CSRs */
#define CSR_MLWID       0x390
#define CSR_SLWID       0x190
#define CSR_MWIDDELEG   0x748
```

**File: `lib/sbi/sbi_hart.c`**

Add WorldGuard detection:
```c
static bool sbi_hart_has_worldguard(struct sbi_scratch *scratch)
{
    unsigned long val;
    
    /* Try to read mlwid CSR - if it traps, WorldGuard is not present */
    if (sbi_trap_csr_read(CSR_MLWID, &val))
        return false;
    
    return true;
}
```

#### Phase 2: WorldGuard Initialization

**File: `lib/sbi/sbi_worldguard.c` (NEW)**

Create WorldGuard initialization module:
```c
#include <sbi/sbi_worldguard.h>
#include <sbi/riscv_encoding.h>

/* WorldGuard configuration */
static struct {
    unsigned int nworlds;
    unsigned int trustedwid;
    bool enabled;
} wg_config;

int sbi_worldguard_init(struct sbi_scratch *scratch)
{
    if (!sbi_hart_has_worldguard(scratch))
        return SBI_OK;  /* WorldGuard not available */
    
    wg_config.enabled = true;
    
    /* Set M-mode WID to trusted (3) */
    csr_write(CSR_MLWID, 3);
    
    /* Set S-mode WID to 2 */
    csr_write(CSR_SLWID, 2);
    
    /* Delegate WID 1,2 to S-mode */
    csr_write(CSR_MWIDDELEG, 0x6);  /* bits 1,2 */
    
    sbi_printf("WorldGuard: enabled, mlwid=%lu, slwid=%lu\n",
               csr_read(CSR_MLWID), csr_read(CSR_SLWID));
    
    return SBI_OK;
}
```

**File: `lib/sbi/sbi_init.c`**

Call WorldGuard init during boot:
```c
/* In sbi_init() or sbi_hart_init() */
rc = sbi_worldguard_init(scratch);
if (rc)
    sbi_hart_hang();
```

#### Phase 3: wgChecker Configuration (Optional)

If OpenSBI needs to configure wgChecker slots:

**File: `lib/sbi/sbi_worldguard.c`**

```c
/* wgChecker MMIO registers */
#define WGC_DRAM_BASE   0x6000000UL
#define WGC_SLOT_BASE   0x100
#define WGC_SLOT_SIZE   0x020

static void wgc_write64(unsigned long addr, uint64_t val)
{
    *(volatile uint64_t *)addr = val;
}

int sbi_worldguard_configure_dram(void)
{
    /* Example: Lock critical regions for M-mode only */
    unsigned long slot_addr = WGC_DRAM_BASE + WGC_SLOT_BASE + 2 * WGC_SLOT_SIZE;
    
    /* Set slot[2] to protect OpenSBI memory (0xA0000000-0xB0000000) */
    wgc_write64(slot_addr + 0x00, 0xB0000000 >> 2);  /* addr */
    wgc_write64(slot_addr + 0x08, 0xC0);              /* perm: W3 RW only */
    wgc_write32(slot_addr + 0x10, 0x1);               /* cfg: TOR */
    
    return SBI_OK;
}
```

#### Phase 4: SBI Extension for WorldGuard

**File: `lib/sbi/sbi_ecall_worldguard.c` (NEW)**

Implement SBI extension for S-mode WorldGuard management:
```c
#include <sbi/sbi_ecall.h>
#include <sbi/sbi_ecall_interface.h>

#define SBI_EXT_WORLDGUARD  0x57475244  /* "WGRD" */

/* SBI WorldGuard function IDs */
#define SBI_EXT_WG_GET_NWORLDS   0
#define SBI_EXT_WG_GET_SLWID     1
#define SBI_EXT_WG_SET_SLWID     2

static int sbi_ecall_worldguard_handler(unsigned long extid,
                                        unsigned long funcid,
                                        struct sbi_trap_regs *regs,
                                        struct sbi_ecall_return *out)
{
    switch (funcid) {
    case SBI_EXT_WG_GET_NWORLDS:
        out->value = wg_config.nworlds;
        break;
    case SBI_EXT_WG_GET_SLWID:
        out->value = csr_read(CSR_SLWID);
        break;
    case SBI_EXT_WG_SET_SLWID:
        csr_write(CSR_SLWID, regs->a0);
        break;
    default:
        return SBI_ENOTSUPP;
    }
    return SBI_OK;
}

struct sbi_ecall_extension ecall_worldguard = {
    .extid_start = SBI_EXT_WORLDGUARD,
    .extid_end = SBI_EXT_WORLDGUARD,
    .handle = sbi_ecall_worldguard_handler,
};
```

### Testing Steps

1. **Build OpenSBI with patches**
   ```bash
   cd sources/opensbi
   make PLATFORM=generic CROSS_COMPILE=riscv64-linux-gnu-
   ```

2. **Run QEMU with patched OpenSBI**
   ```bash
   ./build/qemu/qemu-system-riscv64 \
       -M virt,wg=on,wg-nworlds=4,wg-trustedwid=3,wg-hwbypass=off \
       -m 2G -smp 4 -nographic \
       -bios ./sources/opensbi/build/platform/generic/firmware/fw_dynamic.bin \
       -kernel ./build/u-boot/u-boot.bin
   ```

3. **Verify WorldGuard initialization in boot log**
   ```
   OpenSBI v1.7
   ...
   WorldGuard: enabled, mlwid=3, slwid=2
   ...
   ```

4. **Test from Linux**
   ```bash
   # Read CSR values via /dev/mem or custom driver
   # Verify world assignments
   ```

### WID Assignment Strategy

| Mode | WID | Purpose |
|------|-----|---------|
| M-mode | 3 | OpenSBI - Trusted, full access |
| S-mode (kernel) | 2 | Linux kernel - Protected kernel memory |
| U-mode (apps) | 1 | User applications - Restricted access |
| Boot/Reserved | 0 | Initial boot, transitions to WID 3 |

### Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `include/sbi/riscv_encoding.h` | Modify | Add CSR definitions |
| `include/sbi/sbi_worldguard.h` | Create | WorldGuard API header |
| `lib/sbi/sbi_worldguard.c` | Create | WorldGuard implementation |
| `lib/sbi/sbi_init.c` | Modify | Call WG init |
| `lib/sbi/sbi_ecall_worldguard.c` | Create | SBI extension |
| `lib/sbi/objects.mk` | Modify | Add new source files |

### Estimated Effort

- Phase 1 (Detection): 1-2 hours
- Phase 2 (Init): 2-4 hours
- Phase 3 (wgChecker): 4-6 hours (optional)
- Phase 4 (SBI Extension): 4-8 hours
- Testing & Debug: 4-8 hours

**Total: 15-28 hours**

---

## References

- [RISC-V WorldGuard Specification](https://github.com/riscv/riscv-worldguard)
- [OpenSBI Documentation](https://github.com/riscv-software-src/opensbi/tree/master/docs)
- QEMU WorldGuard: `sources/qemu/hw/misc/riscv_wgchecker.c`
- QEMU CSR impl: `sources/qemu/target/riscv/csr.c` (lines 5476-5578)
