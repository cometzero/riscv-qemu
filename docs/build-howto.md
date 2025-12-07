# Build Guide

## Prerequisites

Install required packages on Ubuntu 24.04:

```bash
sudo apt update
sudo apt install -y \
    build-essential git python3 \
    gcc-riscv64-linux-gnu g++-riscv64-linux-gnu \
    libglib2.0-dev libpixman-1-dev ninja-build meson \
    flex bison libssl-dev bc libncurses-dev \
    cpio unzip rsync wget
```

Verify cross-compiler:

```bash
riscv64-linux-gnu-gcc --version
```

## Build Steps

### Full Build

```bash
./scripts/build_all.sh
```

### Per-Component Build

```bash
./scripts/build_qemu.sh
./scripts/build_opensbi.sh
./scripts/build_uboot.sh
./scripts/build_linux.sh
./scripts/build_buildroot.sh
```

## Build Outputs

All outputs are placed in `./build/`:

| Component | Output |
|-----------|--------|
| QEMU | `build/qemu/build/qemu-system-riscv64` |
| OpenSBI | `build/opensbi/platform/generic/firmware/fw_dynamic.bin` |
| U-Boot SPL | `build/u-boot/spl/u-boot-spl.bin` |
| U-Boot FIT | `build/u-boot/u-boot.itb` |
| Linux | `build/linux/arch/riscv/boot/Image` |
| Buildroot | `build/rootfs/images/rootfs.cpio` |

## Clean

```bash
./scripts/clean.sh          # Remove build outputs
./scripts/clean.sh --distclean  # Remove everything including logs
```
