# OP-TEE Memory Layout and PMP Configuration

## Overview

RISC-V uses Physical Memory Protection (PMP) for hardware-based isolation between the Trusted Execution Environment (TEE) and Rich Execution Environment (REE).

## Memory Map

Based on RISE project specification for QEMU virt platform:

```
┌────────────────────────────────────────┐ 0xFFFF_FFFF
│                                        │
│           (unused)                     │
│                                        │
├────────────────────────────────────────┤ 0xF220_0000
│     Shared Memory (TEE ↔ REE)          │ 2 MiB
│     0xF200_0000 - 0xF21F_FFFF          │
├────────────────────────────────────────┤ 0xF200_0000
│                                        │
│           (unused)                     │
│                                        │
├────────────────────────────────────────┤ 0xF200_0000
│     OP-TEE OS + Trusted Applications   │ 16 MiB
│     0xF100_0000 - 0xF1FF_FFFF          │
├────────────────────────────────────────┤ 0xF100_0000
│                                        │
│           (unused)                     │
│                                        │
├────────────────────────────────────────┤ 0x8016_0000
│     OpenSBI (M-mode firmware)          │ ~384 KiB
│     0x8010_0000 - 0x8015_FFFF          │
├────────────────────────────────────────┤ 0x8010_0000
│     U-Boot SPL                         │ ~40 KiB
│     0x8000_0000 - 0x8000_A000          │
├────────────────────────────────────────┤ 0x8000_0000
│                                        │
│           DRAM                         │
│                                        │
└────────────────────────────────────────┘ 0x0000_0000
```

## PMP Regions

| Region | Address Range | Access | Purpose |
|--------|---------------|--------|---------|
| 0 | 0xF100_0000 - 0xF1FF_FFFF | TEE only | OP-TEE secure memory |
| 1 | 0xF200_0000 - 0xF21F_FFFF | TEE+REE | Shared memory |
| 2 | 0x8000_0000 - 0xEFFF_FFFF | REE | Normal world DRAM |

## Access Control

### Secure World (TEE)
- Full access to OP-TEE region (0xF100_0000)
- Full access to shared memory (0xF200_0000)
- No access to REE private memory

### Normal World (REE)
- No access to OP-TEE region
- Read/Write access to shared memory
- Full access to REE DRAM

## Configuration

### OP-TEE OS (configs/optee/qemu_virt.mk)

```makefile
CFG_TZDRAM_START = 0xF1000000
CFG_TZDRAM_SIZE = 0x01000000  # 16 MiB
CFG_SHMEM_START = 0xF2000000
CFG_SHMEM_SIZE = 0x00200000   # 2 MiB
```

### OpenSBI Domain Configuration

OpenSBI uses domain configuration to set up PMP regions. This is configured via device tree or platform code.

## QEMU Requirements

QEMU virt platform provides:
- 16 PMP regions (sufficient for TEE/REE isolation)
- Configurable memory size

## References

- [RISC-V Privileged Specification - PMP](https://riscv.org/specifications/privileged-isa/)
- [RISE Project OP-TEE Implementation](https://lf-rise.atlassian.net/wiki/spaces/HOME/pages/8587868/)
- [OP-TEE Memory Layout](https://optee.readthedocs.io/en/latest/architecture/core.html)
