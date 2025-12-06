# Build Instructions

This document provides detailed instructions for building all components of the RISC-V QEMU Boot Chain.

## Prerequisites

Ensure you have set up the environment:
```bash
./scripts/setup-env.sh
```

## Quick Start

To build everything:
```bash
make all
```

To clean everything:
```bash
make clean
```

## Component Builds

### 1. QEMU
Builds QEMU from source with RISC-V support.
- **Command**: `./scripts/build-qemu.sh` or `make qemu-build`
- **Output**: `build/toolchain/qemu/bin/qemu-system-riscv64`
- **Log**: `build/logs/qemu-build.log`

### 2. OpenSBI
Builds OpenSBI firmware (Machine Mode).
- **Command**: `./scripts/build-opensbi.sh` or `make opensbi-build`
- **Output**: `build/opensbi/platform/generic/firmware/fw_dynamic.bin`
- **Log**: `build/logs/opensbi-build.log`

### 3. U-Boot
Builds U-Boot bootloader (Supervisor Mode).
- **Command**: `./scripts/build-uboot.sh` or `make uboot-build`
- **Output**: `build/u-boot/u-boot.bin`, `build/u-boot/u-boot.itb`
- **Log**: `build/logs/u-boot-build.log`

### 4. Linux Kernel
Builds the Linux Kernel.
- **Command**: `./scripts/build-linux.sh` or `make linux-build`
- **Output**: `build/linux/arch/riscv/boot/Image`
- **Log**: `build/logs/linux-build.log`

### 5. Buildroot (Root Filesystem)
Builds the root filesystem.
- **Command**: `./scripts/build-buildroot.sh` or `make buildroot-build`
- **Output**: `build/buildroot/images/rootfs.ext2`
- **Log**: `build/logs/buildroot-build.log`

## Configuration

You can customize the configuration for each component using menuconfig:

- **U-Boot**: `./scripts/menuconfig-uboot.sh` or `make uboot-config`
- **Linux**: `./scripts/menuconfig-linux.sh` or `make linux-config`
- **Buildroot**: `./scripts/menuconfig-buildroot.sh` or `make buildroot-config`

## Incremental Rebuilds

For faster development, use the rebuild scripts which skip the configuration step and only rebuild changed files:

- `make uboot-rebuild`
- `make opensbi-rebuild`
- `make linux-rebuild`
- `make buildroot-rebuild`

## U-Boot SPL with WorldGuard

### Building SPL

```bash
cd sources/u-boot
make CROSS_COMPILE=riscv64-linux-gnu- qemu-riscv64_spl_defconfig
make CROSS_COMPILE=riscv64-linux-gnu- -j$(nproc)
```

**Outputs**:
- `spl/u-boot-spl.bin` - SPL binary (~40KB)
- `u-boot.bin` - U-Boot proper

### Creating FIT Image

```bash
mkdir -p build/fit
cd build/fit

# Copy components
cp ../opensbi/platform/generic/firmware/fw_dynamic.bin .
cp ../../sources/u-boot/u-boot-nodtb.bin .
cp ../../dts/qemu-virt-worldguard.dtb .

# Create FIT image
../../sources/u-boot/tools/mkimage -f fit-opensbi-uboot.its u-boot-spl.itb
```

**Output**: `u-boot-spl.itb` (~885KB)

### SPL Configuration Options

Key configs in `qemu-riscv64_spl_defconfig`:

```
CONFIG_SPL=y
CONFIG_SPL_OPENSBI=y
CONFIG_SPL_LOAD_FIT=y
CONFIG_SPL_RAM_SUPPORT=y
CONFIG_SPL_TEXT_BASE=0x81000000
```

