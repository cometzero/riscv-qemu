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
| Linux (OP-TEE) | `configs/linux/optee.fragment` |
| Buildroot | `configs/buildroot/qemu_riscv64_minimal.defconfig` |
| OP-TEE | `configs/optee/qemu_virt.mk` |
| OpenSBI (OP-TEE) | `configs/opensbi/optee_spd.mk` |

## Dual-Mode Operation (OP-TEE)

The project supports two boot modes:

### Standard Mode (Default)

Boot without OP-TEE:

```bash
./scripts/build_all.sh
./scripts/run_qemu.sh
```

### OP-TEE Mode

Boot with OP-TEE Trusted Execution Environment:

```bash
./scripts/build_all.sh --optee
./scripts/run_qemu.sh --optee
```

### Switching Between Modes

Both modes can coexist. The `--optee` flag determines:

| Flag | Build | Boot |
|------|-------|------|
| None | Standard components | Normal boot |
| `--optee` | OP-TEE + patched components | TEE-enabled boot |

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

### Enable OP-TEE Debug Logging

Edit `configs/optee/qemu_virt.mk`:

```makefile
CFG_TEE_CORE_LOG_LEVEL = 4  # 0=none, 1=error, 2=info, 3=debug, 4=flow
```

Rebuild:

```bash
./scripts/build_optee.sh
```

