# RISC-V Boot Chain Debugging Guide

This guide provides instructions for debugging individual components of the RISC-V boot chain and the overall system.

## 1. Component Rebuild & Incremental Development

To speed up development, use the provided incremental rebuild scripts. These scripts only rebuild the specific component without cleaning the entire build tree.

### U-Boot
- **Rebuild**: `./scripts/rebuild-uboot.sh`
- **Clean**: `./scripts/clean-uboot.sh`
- **Log**: `build/logs/u-boot-rebuild.log`
- **Artifacts**: `build/u-boot/u-boot.bin`, `build/u-boot/u-boot.itb`

### OpenSBI
- **Rebuild**: `./scripts/rebuild-opensbi.sh`
- **Clean**: `./scripts/clean-opensbi.sh`
- **Log**: `build/logs/opensbi-rebuild.log`
- **Artifacts**: `build/opensbi/platform/generic/firmware/fw_dynamic.bin`

### Linux Kernel
- **Rebuild**: `./scripts/rebuild-linux.sh`
- **Clean**: `./scripts/clean-linux.sh`
- **Log**: `build/logs/linux-rebuild.log`
- **Artifacts**: `build/linux/arch/riscv/boot/Image`

### Buildroot (Rootfs)
- **Rebuild**: `./scripts/rebuild-buildroot.sh`
- **Clean**: `./scripts/clean-buildroot.sh`
- **Log**: `build/logs/buildroot-rebuild.log`
- **Artifacts**: `build/buildroot/images/rootfs.ext2`

### Clean All
To remove **ALL** build artifacts and start fresh:
```bash
./scripts/clean.sh
```

## 2. QEMU Debugging

### GDB Debugging
To debug the boot chain with GDB:

1. Edit `scripts/run-qemu.sh` and add the `-s -S` options to the QEMU command:
   - `-s`: Shorthand for `-gdb tcp::1234`
   - `-S`: Freeze CPU at startup (wait for GDB to connect)

2. Run QEMU:
   ```bash
   ./scripts/run-qemu.sh
   ```

3. In a separate terminal, start GDB:
   ```bash
   gdb-multiarch build/linux/vmlinux
   ```

4. Connect to QEMU:
   ```gdb
   (gdb) target remote localhost:1234
   (gdb) break start_kernel
   (gdb) continue
   ```

### QEMU Logging
To enable QEMU guest error logging (useful for debugging crashes):

1. Edit `scripts/run-qemu.sh` and add:
   ```bash
   -d guest_errors,unimp -D qemu.log
   ```

2. Run QEMU and check `qemu.log` for error messages.

## 3. Log Files

All build logs are stored in `build/logs/`:

| Component | Build Log | Rebuild Log |
|-----------|-----------|-------------|
| QEMU | `qemu-build.log` | N/A |
| OpenSBI | `opensbi-build.log` | `opensbi-rebuild.log` |
| U-Boot | `u-boot-build.log` | `u-boot-rebuild.log` |
| Linux | `linux-build.log` | `linux-rebuild.log` |
| Buildroot | `buildroot-build.log` | `buildroot-rebuild.log` |

## 4. Common Issues

### U-Boot "Bad Linux ARM64 Image magic"
- **Cause**: U-Boot trying to boot a raw Image file as a uImage or vice versa, or architecture mismatch.
- **Fix**: Ensure `booti` command is used for raw Image files in U-Boot shell.

### Kernel Panic "VFS: Unable to mount root fs"
- **Cause**: Rootfs not found or driver missing.
- **Fix**: Check `root=/dev/vda` kernel argument and ensure `virtio-blk` driver is compiled into the kernel.

### OpenSBI "illegal instruction"
- **Cause**: Mismatch between QEMU CPU extensions and OpenSBI compilation options.
- **Fix**: Ensure QEMU uses `-cpu rv64` and OpenSBI is built for `PLATFORM=generic`.
