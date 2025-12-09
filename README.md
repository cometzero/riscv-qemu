# RISC-V QEMU Boot Flow

A complete, reproducible RISC-V boot flow on QEMU for learning and experimentation.

## Overview

This project implements the full RISC-V boot sequence:

```
QEMU BootROM → U-Boot SPL → OpenSBI → U-Boot proper → Linux Kernel → Buildroot
```

### OP-TEE Support (Experimental)

Optional Trusted Execution Environment support:

```
U-Boot SPL → OpenSBI (OP-TEE SPD) → U-Boot proper → Linux (TEE driver) → Buildroot
```

## Quick Start

### Prerequisites

Ubuntu 24.04 LTS with:

```bash
sudo apt install -y \
    build-essential git python3 python3-pip \
    gcc-riscv64-linux-gnu g++-riscv64-linux-gnu \
    libglib2.0-dev libpixman-1-dev ninja-build meson \
    flex bison libssl-dev bc libncurses-dev \
    cpio unzip rsync wget

# For OP-TEE build
pip3 install --user --break-system-packages pyelftools
```

### Build and Run

```bash
# Clone and setup
git clone <repository-url>
cd riscv-qemu-bootflow
git submodule update --init --recursive

# Build all components
./scripts/build_all.sh

# Run QEMU
./scripts/run_qemu.sh
```

### Build with OP-TEE

```bash
# Build with OP-TEE support
./scripts/build_all.sh --optee

# Run QEMU with OP-TEE
./scripts/run_qemu.sh --optee
```

### Test

```bash
python3 test/run_boot_test.py
```

## Project Structure

```
├── docs/           # Documentation
├── sources/        # Git submodules (QEMU, U-Boot, OpenSBI, Linux, Buildroot, OP-TEE)
├── build/          # Build outputs (git-ignored)
├── test/           # Test harness
├── configs/        # Configuration files
├── scripts/        # Build and run scripts
├── patches/        # OP-TEE patches for submodules
└── specs/          # Specification documents
```

## Documentation

- [Boot Flow](docs/boot-flow.md) - Boot sequence explanation
- [Build Guide](docs/build-howto.md) - Step-by-step build instructions
- [Testing](docs/testing.md) - Test execution guide
- [Configuration](docs/configuration.md) - Configuration modification guide
- [OP-TEE Boot Flow](docs/optee-boot-flow.md) - OP-TEE integration guide
- [OP-TEE Patches](docs/optee-patches.md) - RISE project patch information

## License

See individual component licenses in `sources/`.

