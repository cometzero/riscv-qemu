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
