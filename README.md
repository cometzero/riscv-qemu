# RISC-V QEMU Boot Flow

A complete, reproducible RISC-V boot flow on QEMU for learning and experimentation.

## Overview

This project implements the full RISC-V boot sequence:

```
QEMU BootROM → U-Boot SPL → OpenSBI → U-Boot proper → Linux Kernel → Buildroot
```

## Quick Start

### Prerequisites

Ubuntu 24.04 LTS with:

```bash
sudo apt install -y \
    build-essential git python3 \
    gcc-riscv64-linux-gnu g++-riscv64-linux-gnu \
    libglib2.0-dev libpixman-1-dev ninja-build meson \
    flex bison libssl-dev bc libncurses-dev \
    cpio unzip rsync wget
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

### Test

```bash
python3 test/run_boot_test.py
```

## Project Structure

```
├── docs/           # Documentation
├── sources/        # Git submodules (QEMU, U-Boot, OpenSBI, Linux, Buildroot)
├── build/          # Build outputs (git-ignored)
├── test/           # Test harness
├── configs/        # Configuration files
├── scripts/        # Build and run scripts
└── specs/          # Specification documents
```

## Documentation

- [Boot Flow](docs/boot-flow.md) - Boot sequence explanation
- [Build Guide](docs/build-howto.md) - Step-by-step build instructions
- [Testing](docs/testing.md) - Test execution guide
- [Configuration](docs/configuration.md) - Configuration modification guide

## License

See individual component licenses in `sources/`.
