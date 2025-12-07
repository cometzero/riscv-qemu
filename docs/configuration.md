# Configuration Guide

## Configuration-First Policy

Per project constitution, prefer configuration changes over source code:

1. Kconfig / defconfig changes
2. Device Tree modifications
3. Command-line options
4. Environment variables
5. Source code (last resort)

## Configuration Files

| Component | Config Location |
|-----------|-----------------|
| QEMU | `configs/qemu/run_qemu.conf` |
| U-Boot | `configs/u-boot/qemu_riscv64.env` |
| Linux | `configs/linux/bootargs.fragment` |
| Buildroot | `configs/buildroot/qemu_riscv64_minimal.defconfig` |

## Common Modifications

### Change Kernel Command Line

Edit `configs/linux/bootargs.fragment`:

```
CONFIG_CMDLINE="console=ttyS0 earlycon=sbi root=/dev/ram0 rw"
```

Rebuild:

```bash
./scripts/build_linux.sh
```

### Change U-Boot Boot Delay

Edit `configs/u-boot/qemu_riscv64.env`:

```
bootdelay=3
```

Rebuild:

```bash
./scripts/build_uboot.sh
```

### Add Buildroot Package

Edit `configs/buildroot/qemu_riscv64_minimal.defconfig` and add package option.

Rebuild:

```bash
./scripts/build_buildroot.sh
```
