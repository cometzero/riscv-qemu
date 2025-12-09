# OP-TEE Patches for RISC-V

This document describes the patches extracted from the RISE project for OP-TEE support on RISC-V.

## Source

All patches are extracted from RISE project `dev-optee-mpxy-v5` branch:
- **Date**: 2025-12-09
- **Source**: https://gitlab.com/riseproject/riscv-optee/

## Patch Summary

### OpenSBI Patches (patches/opensbi/)

20 patches for OpenSBI SPD (Secure Payload Dispatcher) support:

| Patch | Description |
|-------|-------------|
| 0001-0003 | Ssstateen extension support |
| 0004-0006 | Build and instruction emulation fixes |
| 0007-0013 | Mailbox and MPXY infrastructure |
| 0014-0017 | SBI spec updates and domain support |
| 0018-0020 | MPXY RPMI drivers for MM and Request Forward |

### OP-TEE OS Patches (patches/optee_os/)

10 patches for RISC-V QEMU virt platform support:

| Patch | Description |
|-------|-------------|
| 0001-0005 | Driver fixes and changelog updates |
| 0006-0010 | RISC-V MPXY extension support for domain communication |

### Linux Patches (patches/linux/)

10 patches for MPXY-based OP-TEE driver:

| Patch | Description |
|-------|-------------|
| 0001-0002 | Device tree bindings for MPXY/RPMI |
| 0003-0006 | SBI MPXY defines and mailbox infrastructure |
| 0007 | OP-TEE driver MPXY communication support |
| 0008-0010 | Device tree and test configurations |

### U-Boot Patches (patches/u-boot/)

10 patches for OP-TEE configuration:

| Patch | Description |
|-------|-------------|
| 0001-0008 | SiFive board configurations for OP-TEE |
| 0009-0010 | OP-TEE driver SBI communication support |

## Applying Patches

Use `git am` to apply patches to each submodule:

```bash
# Apply to OpenSBI
cd sources/opensbi
git am ../../patches/opensbi/*.patch

# Apply to OP-TEE OS
cd sources/optee_os
git am ../../patches/optee_os/*.patch

# Apply to Linux
cd sources/linux
git am ../../patches/linux/*.patch

# Apply to U-Boot (optional)
cd sources/u-boot
git am ../../patches/u-boot/*.patch
```

## Notes

- These patches are extracted from a development branch and may require rebasing
- Some patches are marked `[TEMP]` indicating temporary workarounds
- The MPXY extension is still under development in the RISC-V community
