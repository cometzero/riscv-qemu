# OP-TEE Boot Flow Documentation

## Overview

This document describes the boot flow when OP-TEE is enabled on RISC-V QEMU.

## Boot Sequence

```
┌──────────────────┐
│   QEMU BootROM   │
│  (loads SPL)     │
└────────┬─────────┘
         v
┌──────────────────┐
│   U-Boot SPL     │
│  (0x80000000)    │
│  Memory init     │
└────────┬─────────┘
         v
┌──────────────────┐
│    OpenSBI       │
│  (0x80100000)    │
│  + OP-TEE SPD    │◄──── Secure Payload Dispatcher
└────────┬─────────┘
         │
    ┌────┴────┐
    v         v
┌─────────┐ ┌─────────────┐
│ OP-TEE  │ │ U-Boot      │
│   OS    │ │  proper     │
│(Secure) │ │ (Normal)    │
└────┬────┘ └──────┬──────┘
     │             v
     │      ┌─────────────┐
     │      │   Linux     │
     │      │   Kernel    │
     │      │ (TEE driver)│
     │      └──────┬──────┘
     │             v
     │      ┌─────────────┐
     │◄─────│  Buildroot  │
     │  TEE │   rootfs    │
     │ calls│ (xtest, CA) │
     │      └─────────────┘
```

## Memory Layout

| Address Range | Size | Component |
|---------------|------|-----------|
| 0xF200_0000 - 0xF21F_FFFF | 2 MiB | Shared memory (TEE↔REE) |
| 0xF100_0000 - 0xF1FF_FFFF | 16 MiB | OP-TEE OS + TAs |
| 0x8010_0000 - 0x8015_FFFF | ~384 KiB | OpenSBI |
| 0x8000_0000 - 0x8000_A000 | 40 KiB | U-Boot SPL |

## Build Commands

```bash
# Build all components with OP-TEE
./scripts/build_all.sh --optee

# Run QEMU with OP-TEE
./scripts/run_qemu.sh --optee
```

## Verification

### Expected Boot Log Messages

When OP-TEE is properly initialized, you should see:

1. **OpenSBI**: Messages indicating OP-TEE SPD loaded
2. **Linux**: TEE driver initialization messages
3. **Devices**: `/dev/tee0` and `/dev/teepriv0` present

### Testing OP-TEE

```bash
# Login as root (no password)
# Check TEE devices
ls -la /dev/tee*

# Run hello world example
optee_example_hello_world

# Run test suite
xtest
```

## Current Status

### Working ✅

- OP-TEE OS builds successfully (`build/optee/core/tee.bin`)
- OpenSBI recognizes OP-TEE domain via Device Tree configuration
- Linux builds with TEE driver (`CONFIG_TEE=y`, `CONFIG_OPTEE=y`)
- QEMU boots with `--optee` mode to Buildroot login prompt
- OpenSBI shows domain configuration:
  - Domain0: root
  - Domain1: optee-domain (0xF1000000)
  - Domain2: linux-domain (OP-TEE memory blocked)

### Partially Working ⚠️

- OP-TEE binary loaded at 0xF1000000 by QEMU
- PMP isolation configured between TEE and REE domains
- Linux TEE driver compiled but not detecting OP-TEE

### Remaining Work for Full Runtime

For complete `/dev/tee0` functionality:

1. **OpenSBI Context Switch**: OpenSBI needs to boot OP-TEE domain first
2. **MPXY Communication**: TEE driver requires MPXY extension for REE↔TEE calls
3. **OP-TEE Initialization**: OP-TEE OS must complete initialization before Linux

## Patch Application

To enable full OP-TEE functionality, apply patches from `patches/` directory:

```bash
# See docs/optee-patches.md for details
cd sources/opensbi && git am ../../patches/opensbi/*.patch
cd sources/linux && git am ../../patches/linux/*.patch
```

## References

- [RISE Project OP-TEE](https://lf-rise.atlassian.net/wiki/spaces/HOME/pages/8587868/OPTEE_00_01+-+OP-TEE+support)
- [OP-TEE Documentation](https://optee.readthedocs.io/)
- [OpenSBI Documentation](https://github.com/riscv-software-src/opensbi)
