# WorldGuard QEMU Integration Guide

This document describes how to use the RISC-V WorldGuard extension with QEMU in this project.

## Overview

WorldGuard is a hardware-based software isolation solution for RISC-V that enables Trusted Execution Environments (TEEs). It uses World IDs (WIDs) to tag memory accesses and Access Control Lists (ACLs) for permission verification.

## QEMU Option

To enable WorldGuard in QEMU:

```bash
-M virt,wg=on
```

This option enables the WorldGuard extension on the virt machine.

## Running with WorldGuard

Use the dedicated WorldGuard script:

```bash
./scripts/run-qemu-worldguard.sh
```

This script runs QEMU with WorldGuard enabled using the full boot chain:
- OpenSBI (SBI firmware)
- U-Boot (bootloader)
- Linux kernel
- Buildroot rootfs

## Verification

The WorldGuard integration has been verified to:
1. Build QEMU successfully with WorldGuard patches
2. Display WorldGuard option in `-M virt,help` output
3. Boot the complete chain (OpenSBI → U-Boot → Linux) without errors
4. Maintain backward compatibility (WorldGuard disabled still works)

## Technical Details

WorldGuard patches were cherry-picked from `cwshu/qemu` branch `riscv-wg-v3` and applied to QEMU v10.1.3. The following components were added:

- `hw/misc/riscv_worldguard.c` - WorldGuard global configuration
- `hw/misc/riscv_wgchecker.c` - WorldGuard Checker implementation
- `hw/riscv/virt.c` - virt machine WorldGuard support
- `target/riscv/csr.c` - WorldGuard CSR implementation

## References

- [RISC-V WorldGuard Specification](https://github.com/riscv/riscv-worldguard)
- [cwshu/qemu WorldGuard Implementation](https://github.com/cwshu/qemu/tree/riscv-wg-v3)

---

## OpenSBI WorldGuard Integration

OpenSBI (v1.7) has been patched to support WorldGuard CSR initialization.

### Features

- **CSR Initialization**: Sets mlwid (trusted WID) and mwiddeleg (WID delegation)
- **Device Tree Parsing**: Reads configuration from `riscv,worldguard` DT node
- **wgChecker Programming**: Programs memory protection slots from DT

### OpenSBI Boot Log

When WorldGuard is enabled:
```
WorldGuard: detected, current mlwid=3
WorldGuard: enabled, mlwid=3, mwiddeleg=0x6
```

### Device Tree Configuration

Add to your DTS:
```dts
worldguard {
    compatible = "riscv,worldguard";
    nworlds = <4>;
    trustedwid = <3>;
    mwiddeleg = <0x6>;
};
```

### Files Modified in OpenSBI

- `include/sbi/riscv_worldguard.h` - CSR and MMIO definitions
- `lib/sbi/sbi_worldguard.c` - Initialization module
- `lib/sbi/sbi_init.c` - Init call integration
- `lib/sbi/objects.mk` - Build system

---

## U-Boot SPL WorldGuard Boot Chain

U-Boot SPL provides an alternative boot path with WorldGuard initialization at the earliest boot stage.

### Boot Chain

```
U-Boot SPL → OpenSBI → U-Boot Proper → Linux
   (M-mode)   (M-mode)   (S-mode)     (S-mode)
```

### Features

- **FIT Image Boot**: SPL loads OpenSBI + U-Boot from FIT image
- **WorldGuard Init**: CSR initialization at SPL stage (optional)
- **DTB Handoff**: Passes WorldGuard config to OpenSBI

### Memory Map

| Address | Component |
|---------|-----------|
| 0x80000000 | OpenSBI |
| 0x80200000 | U-Boot / FIT Image |
| 0x81000000 | U-Boot SPL |

### Running SPL Boot Chain

```bash
qemu-system-riscv64 \
    -M virt,wg=on \
    -m 2G -smp 1 -nographic \
    -kernel sources/u-boot/spl/u-boot-spl.bin \
    -device loader,file=build/fit/u-boot-spl.itb,addr=0x80200000
```

### Creating FIT Image

```bash
cd build/fit
cat > fit-opensbi-uboot.its << 'EOF'
/dts-v1/;
/ {
    description = "SPL FIT Image";
    images {
        opensbi { os = "opensbi"; load = <0x0 0x80000000>; };
        uboot { os = "u-boot"; load = <0x0 0x80200000>; };
        fdt { type = "flat_dt"; };
    };
    configurations { firmware = "opensbi"; loadables = "uboot"; };
};
EOF
mkimage -f fit-opensbi-uboot.its u-boot-spl.itb
```

### SPL Boot Log

```
U-Boot SPL 2024.10
Trying to boot from RAM
SPL: Looking for FIT at 0x80200000
SPL: Found FIT image!
SPL: Jumping to OpenSBI at 0x80000000, next=0x80200000

OpenSBI v1.5.1
Platform Name: riscv-virtio,qemu
```

### Files Modified in U-Boot

- `configs/qemu-riscv64_spl_defconfig` - SPL configuration
- `board/emulation/qemu-riscv/spl/` - SPL WorldGuard modules
- `common/spl/spl_ram.c` - FIT loading debug
- `common/spl/spl_opensbi.c` - OpenSBI handoff debug

### Documentation

- [Testing Guide](../specs/004-uboot-spl-worldguard/testing-guide.md)
- [Test Results](../specs/004-uboot-spl-worldguard/test-results.md)

