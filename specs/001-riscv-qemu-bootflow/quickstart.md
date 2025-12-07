# Quick Start: RISC-V QEMU Boot Flow

**Feature**: `001-riscv-qemu-bootflow`  
**Time to first boot**: ~45-60 minutes (mostly build time)

## Prerequisites

Ubuntu 24.04 LTS x86_64 with the following packages:

```bash
sudo apt update
sudo apt install -y \
    build-essential git python3 \
    gcc-riscv64-linux-gnu g++-riscv64-linux-gnu \
    libglib2.0-dev libpixman-1-dev ninja-build meson \
    flex bison libssl-dev bc libncurses-dev \
    cpio unzip rsync wget
```

**Verify cross-compiler**:
```bash
riscv64-linux-gnu-gcc --version
# Expected: riscv64-linux-gnu-gcc (Ubuntu 13.x.x) ...
```

## Clone and Setup

```bash
# Clone repository
git clone <repository-url> riscv-qemu-bootflow
cd riscv-qemu-bootflow

# Initialize submodules
git submodule update --init --recursive

# Verify prerequisites
./scripts/check_prereqs.sh
```

## Build

```bash
# Full build (all components)
./scripts/build_all.sh

# Or build individually:
./scripts/build_qemu.sh
./scripts/build_opensbi.sh
./scripts/build_uboot.sh
./scripts/build_linux.sh
./scripts/build_buildroot.sh
```

**Build time**: ~30-45 minutes on a 4-core machine (QEMU and Linux are the largest)

## Run

```bash
# Launch QEMU with full boot flow
./scripts/run_qemu.sh

# Expected output sequence:
# 1. U-Boot SPL 2024.xx ...
# 2. OpenSBI v1.x ...
# 3. U-Boot 2024.xx ...
# 4. Linux version 6.x.x ...
# 5. buildroot login:
```

**Exit QEMU**: Press `Ctrl+A` then `X`

## Test

```bash
# Run automated boot test
python3 ./test/run_boot_test.py

# Exit code 0 = success (all milestones found)
# Exit code 1 = failure (missing milestones or errors)
```

## Modify Configuration

### Change kernel command line

```bash
# Edit the bootargs fragment
vi ./configs/linux/bootargs.fragment

# Rebuild kernel
./scripts/build_linux.sh

# Re-test
./scripts/run_qemu.sh
```

### Change U-Boot boot delay

```bash
# Edit U-Boot environment
vi ./configs/u-boot/qemu_riscv64.env

# Rebuild U-Boot
./scripts/build_uboot.sh

# Re-test
./scripts/run_qemu.sh
```

## Directory Overview

| Directory | Contents |
|-----------|----------|
| `./sources/` | Git submodules (upstream code) |
| `./build/` | Build outputs and logs |
| `./configs/` | Configuration files |
| `./scripts/` | Build and run scripts |
| `./test/` | Test harness |
| `./docs/` | Documentation |

## Troubleshooting

| Problem | Solution |
|---------|----------|
| "command not found: riscv64-linux-gnu-gcc" | Install cross-compiler: `apt install gcc-riscv64-linux-gnu` |
| Build fails in QEMU | Install meson/ninja: `apt install meson ninja-build` |
| Test timeout | Increase timeout in `test/run_boot_test.py` |
| "buildroot login:" not appearing | Check kernel cmdline includes `console=ttyS0` |

## Next Steps

- Read `./docs/boot-flow.md` for detailed architecture
- Read `./docs/configuration.md` for customization guide
- Explore individual build scripts to understand the build process
