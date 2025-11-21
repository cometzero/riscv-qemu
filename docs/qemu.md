# QEMU Usage Guide

This document explains how to run and configure QEMU for the RISC-V Boot Chain.

## Running QEMU

To launch the full boot chain:
```bash
./scripts/run-qemu.sh
```
Or using Make:
```bash
make qemu-run
```

## Boot Chain Overview

The boot process follows this sequence:
1. **QEMU** starts and loads OpenSBI (`-bios`).
2. **OpenSBI** (M-mode) initializes hardware and jumps to U-Boot (`-device loader`).
3. **U-Boot** (S-mode) initializes devices and loads the Linux Kernel.
4. **Linux Kernel** (S-mode) boots and mounts the Root Filesystem.
5. **Init** (User-mode) starts from the Rootfs (BusyBox).

## QEMU Arguments

The `run-qemu.sh` script uses the following key arguments:

- `-M virt`: Use the generic RISC-V Virtual Machine.
- `-m 2G`: Allocate 2GB of RAM.
- `-smp 4`: Use 4 vCPUs.
- `-nographic`: Disable graphical output (use serial console).
- `-bios ...`: Path to OpenSBI firmware.
- `-device loader,file=...`: Loads U-Boot as a payload.
- `-drive file=...,format=raw,id=hd0`: Attaches the root filesystem image.
- `-netdev user,id=net0`: Configures user-mode networking.

## Networking

The default network configuration uses SLIRP (User Networking):
- Guest IP: 10.0.2.15
- Host Gateway: 10.0.2.2
- DNS: 10.0.2.3

To forward ports (e.g., SSH):
Edit `scripts/run-qemu.sh` and add:
`-netdev user,id=net0,hostfwd=tcp::2222-:22`

## Debugging

See [debugging.md](debugging.md) for detailed debugging instructions, including GDB usage and logging.

## Exiting QEMU

To exit QEMU:
- Press `Ctrl+A` then `x`.
