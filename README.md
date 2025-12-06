# RISC-V QEMU Boot Chain Verification

This project provides a complete RISC-V boot chain verification environment for QEMU virt machines, including U-Boot SPL, OpenSBI, U-Boot, Linux Kernel, and Buildroot-based initramfs.

## Overview

The goal of this project is to build and verify a complete RISC-V boot chain on Ubuntu 24.04 headless servers, demonstrating the end-to-end boot process from firmware to userspace.

### Boot Chain Components

- **QEMU**: RISC-V system emulator (built from source)
- **U-Boot SPL**: Secondary Program Loader
- **OpenSBI**: RISC-V Supervisor Binary Interface firmware
- **U-Boot**: Second-stage bootloader
- **Linux Kernel**: RISC-V 64-bit kernel
- **Buildroot**: BusyBox-based root filesystem (initramfs)

## Quick Start

### Prerequisites

- Ubuntu 24.04 LTS (headless)
- sudo/root access for package installation
- Internet connection for downloading sources and toolchains
- Minimum 4 cores, 8GB RAM recommended

### Installation

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd risc-v
   ```

2. **Initialize submodules**:
   ```bash
   git submodule update --init --recursive
   ```

3. **Install dependencies**:
   ```bash
   ./scripts/setup-env.sh
   ```

4. **Build all components**:
   ```bash
   ./scripts/build-all.sh
   ```

5. **Run QEMU**:
   ```bash
   ./scripts/run-qemu.sh
   ```

## Project Structure

```
risc-v/
├── sources/          # Git submodules for all components
│   ├── qemu/
│   ├── u-boot/
│   ├── opensbi/
│   ├── linux/
│   └── buildroot/
├── configs/          # Configuration files for each component
├── scripts/          # Build and execution scripts
├── docs/             # Documentation
├── build/            # Build artifacts (out-of-tree builds)
│   ├── qemu/
│   ├── u-boot/
│   ├── opensbi/
│   ├── linux/
│   ├── buildroot/
│   ├── images/       # Final boot images
│   └── logs/         # Build logs
└── specs/            # Feature specifications and plans
```

## Documentation

- [Build Guide](docs/build.md): Detailed build instructions.
- [Debugging Guide](docs/debugging.md): Debugging tips and workflows.
- [QEMU Guide](docs/qemu.md): How to run and use QEMU.
- [Custom Rootfs Guide](docs/custom-rootfs.md): Adding packages and customizing the rootfs.
- [Version Management](docs/version-management.md): Managing submodules and versions.
- [WorldGuard Guide](docs/worldguard.md): RISC-V WorldGuard integration.

## WorldGuard Boot Modes

This project supports RISC-V WorldGuard hardware isolation:

### Mode 1: Direct Boot (OpenSBI as BIOS)

```bash
./scripts/run-qemu-worldguard.sh
# Or manually:
qemu-system-riscv64 -M virt,wg=on \
    -bios fw_dynamic.bin -kernel u-boot.bin -dtb qemu-virt-worldguard.dtb
```

### Mode 2: SPL Boot Chain

```bash
qemu-system-riscv64 -M virt,wg=on \
    -kernel u-boot-spl.bin \
    -device loader,file=u-boot-spl.itb,addr=0x80200000
```

Boot chain: `SPL → OpenSBI → U-Boot → Linux`

See [WorldGuard Guide](docs/worldguard.md) for details.

## Development Workflow

### Building Individual Components

```bash
# Build QEMU from source
./scripts/build-qemu.sh

# Build U-Boot
./scripts/build-u-boot.sh

# Build OpenSBI
./scripts/build-opensbi.sh

# Build Linux Kernel
./scripts/build-linux.sh

# Build Buildroot rootfs
./scripts/build-buildroot.sh
```

### Cleaning Build Artifacts

```bash
# Clean all components
./scripts/clean.sh

# Clean specific component
./scripts/clean-u-boot.sh
./scripts/clean-linux.sh
```

### Configuration

```bash
# Configure U-Boot
./scripts/menuconfig-u-boot.sh

# Configure Linux Kernel
./scripts/menuconfig-linux.sh

# Configure Buildroot
./scripts/menuconfig-buildroot.sh
```

## Success Criteria

- ✅ Complete boot chain builds in under 30 minutes on standard dev server
- ✅ QEMU boots to busybox shell within 60 seconds
- ✅ All build logs saved to `build/logs/` for debugging
- ✅ Individual components can be rebuilt in under 5 minutes

## License

See [LICENSE](LICENSE) file for details.

## Contributing

This project follows the RISC-V QEMU Boot Chain Project Constitution. Please refer to `.specify/memory/constitution.md` for development principles and guidelines.

## Support

For issues, questions, or contributions, please refer to the project documentation in the `docs/` directory.
