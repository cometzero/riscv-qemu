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

### Working

- OP-TEE OS builds successfully (`tee.bin`)
- OpenSBI builds with --optee flag
- Linux builds with TEE driver config fragment
- QEMU boots with --optee mode

### Requires RISE Patches

The following require applying RISE project patches to submodules:

- OpenSBI: MPXY/RPMI and SPD patches for OP-TEE integration
- Linux: TEE driver patches for RISC-V MPXY communication
- Full OP-TEE runtime functionality

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
