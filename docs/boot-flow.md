# Boot Flow

## Overview

This document describes the complete RISC-V boot sequence on QEMU.

## Boot Sequence

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           QEMU RISC-V virt Machine                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌───────────┐    ┌───────────┐    ┌───────────┐    ┌───────────────────┐  │
│  │  BootROM  │───►│ U-Boot    │───►│  OpenSBI  │───►│ U-Boot proper     │  │
│  │  (QEMU)   │    │   SPL     │    │ fw_dynamic │    │ (S-mode)          │  │
│  │           │    │ (M-mode)  │    │ (M-mode)  │    │                   │  │
│  └───────────┘    └───────────┘    └───────────┘    └───────────────────┘  │
│       │                │                │                    │              │
│       │   -bios        │  FIT image     │   SBI ecall        │              │
│       └────────────────┘  u-boot.itb    └────────────────────┘              │
│                                                                             │
│                         ┌───────────────────┐    ┌───────────────────────┐  │
│                         │   Linux Kernel    │───►│  Buildroot rootfs     │  │
│                         │   (S-mode)        │    │  (init → login)       │  │
│                         └───────────────────┘    └───────────────────────┘  │
│                                │                          │                 │
│                           Device Tree                  initramfs            │
│                           + cmdline                    (cpio)               │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Boot Stages

| Stage | Component | Mode | Description |
|-------|-----------|------|-------------|
| 0 | QEMU BootROM | - | Reset vector, jumps to SPL |
| 1 | U-Boot SPL | M-mode | Loads FIT image with OpenSBI + U-Boot |
| 2 | OpenSBI | M-mode | M-mode firmware, provides SBI to S-mode |
| 3 | U-Boot proper | S-mode | Loads kernel and device tree |
| 4 | Linux Kernel | S-mode | Boots with initramfs |
| 5 | Buildroot | S-mode | Userspace init, login prompt |

## Milestones

Each stage outputs a specific pattern for verification:

1. **SPL**: `U-Boot SPL`
2. **OpenSBI**: `OpenSBI v`
3. **U-Boot**: `U-Boot 20`
4. **Linux**: `Linux version`
5. **Login**: `buildroot login:`

## References

- [OpenSBI QEMU virt](https://github.com/riscv-software-src/opensbi/blob/master/docs/platform/qemu_virt.md)
- [U-Boot QEMU RISC-V](https://docs.u-boot.org/en/latest/board/emulation/qemu-riscv.html)
