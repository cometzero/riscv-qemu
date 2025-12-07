# Research: RISC-V QEMU Boot Flow

**Feature**: `001-riscv-qemu-bootflow`  
**Date**: 2025-12-07

## Boot Architecture Research

### Decision: 64-bit RISC-V (RV64) on QEMU virt machine

**Rationale**:
- RV64 is the predominant architecture for Linux-capable RISC-V systems
- QEMU `virt` machine is the most mature and well-documented platform
- Better toolchain support in Ubuntu (`riscv64-linux-gnu-` readily available)
- More upstream examples and documentation available

**Alternatives Considered**:
- RV32: Smaller footprint but less common for Linux, fewer examples
- QEMU `spike` machine: Less feature-rich than `virt`

### Decision: U-Boot SPL with FIT Image Boot Flow

**Rationale**:
- SPL provides realistic boot flow matching real hardware
- FIT image bundles OpenSBI + U-Boot proper cleanly
- U-Boot's `qemu-riscv64_spl_defconfig` is well-maintained
- OpenSBI `fw_dynamic.bin` works with FIT boot method
- Clear handoff: SPL → OpenSBI → U-Boot proper

**Alternatives Considered**:
- Direct OpenSBI payload: Simpler but bypasses SPL (less realistic)
- Separate BIOS loading: More complex QEMU command line
- OpenSBI `fw_payload`: Bundles everything in OpenSBI (less modular)

Reference: [U-Boot QEMU RISC-V Documentation](https://docs.u-boot.org/en/latest/board/emulation/qemu-riscv.html)

### Decision: Initramfs for Root Filesystem

**Rationale**:
- Simplest integration: Single kernel + initramfs bundle
- No disk image management complexity
- Faster boot (no block device initialization)
- Buildroot supports initramfs output directly

**Alternatives Considered**:
- virtio-blk disk image: More realistic but adds complexity
- NFS root: Requires network setup
- Disk with EXT4: Production-like but overkill for learning/testing

## Upstream Documentation Sources

| Component | Documentation URL | Key Findings |
|-----------|------------------|--------------|
| OpenSBI | [qemu_virt.md](https://github.com/riscv-software-src/opensbi/blob/master/docs/platform/qemu_virt.md) | Use `PLATFORM=generic`, `fw_dynamic.bin` for FIT |
| U-Boot | [qemu-riscv.html](https://docs.u-boot.org/en/latest/board/emulation/qemu-riscv.html) | `qemu-riscv64_spl_defconfig`, `OPENSBI` env var |
| QEMU | QEMU docs | `-M virt`, `-bios` for SPL, `-device loader` for FIT |

## Build Command Summary

Based on upstream documentation:

```bash
# OpenSBI
make PLATFORM=generic

# U-Boot (with OpenSBI)
export OPENSBI=/path/to/fw_dynamic.bin
make qemu-riscv64_spl_defconfig
make

# QEMU invocation
qemu-system-riscv64 -M virt -m 256M -nographic \
    -bios spl/u-boot-spl.bin \
    -device loader,file=u-boot.itb,addr=0x80200000
```

## Host Prerequisites Research

### Required Ubuntu 24.04 Packages

```bash
# Build essentials
apt install build-essential git

# Cross-compiler
apt install gcc-riscv64-linux-gnu g++-riscv64-linux-gnu

# QEMU build dependencies
apt install libglib2.0-dev libpixman-1-dev ninja-build meson

# Kernel build dependencies
apt install flex bison libssl-dev bc libncurses-dev

# Buildroot dependencies
apt install cpio unzip rsync wget

# Python for testing
apt install python3
```

### Verification Command

```bash
riscv64-linux-gnu-gcc --version  # Should show 13.x on Ubuntu 24.04
```

## Memory Map Research

QEMU virt machine memory layout (relevant addresses):

| Address | Usage |
|---------|-------|
| `0x00001000` | QEMU ROM (reset vector) |
| `0x80000000` | DRAM start, SPL/OpenSBI load address |
| `0x80200000` | U-Boot proper load address (in FIT) |
| `0x80400000` | Typical Linux kernel load address |

Source: QEMU source code and U-Boot device tree
