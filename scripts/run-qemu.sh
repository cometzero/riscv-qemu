#!/bin/bash
# Script to run QEMU with the built components
# This script assembles the boot chain and launches QEMU

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source the toolchain environment
source "${SCRIPT_DIR}/toolchain-env.sh"

# Paths to components
QEMU_BIN="${PROJECT_ROOT}/build/qemu/install/bin/qemu-system-riscv64"
OPENSBI_BIN="${PROJECT_ROOT}/build/opensbi/platform/generic/firmware/fw_dynamic.bin"
UBOOT_BIN="${PROJECT_ROOT}/build/u-boot/u-boot.bin"
KERNEL_IMAGE="${PROJECT_ROOT}/build/linux/arch/riscv/boot/Image"
ROOTFS_IMAGE="${PROJECT_ROOT}/build/buildroot/images/rootfs.ext2"

# Check if components exist
check_file() {
    if [ ! -f "$1" ]; then
        echo "ERROR: Component not found: $1"
        echo "Please build all components first using ./scripts/build-all.sh or individual scripts."
        exit 1
    fi
}

echo "Checking components..."
check_file "${QEMU_BIN}"
check_file "${OPENSBI_BIN}"
check_file "${UBOOT_BIN}"
check_file "${KERNEL_IMAGE}"
# check_file "${ROOTFS_IMAGE}" # Optional for now, might not be ready

echo "========================================="
echo "Starting RISC-V QEMU Boot Chain"
echo "========================================="
echo "QEMU:      ${QEMU_BIN}"
echo "OpenSBI:   ${OPENSBI_BIN}"
echo "U-Boot:    ${UBOOT_BIN}"
echo "Kernel:    ${KERNEL_IMAGE}"
echo "Rootfs:    ${ROOTFS_IMAGE}"
echo "========================================="
echo ""
echo "Press Ctrl+A, X to exit QEMU"
echo ""

# Run QEMU
# -M virt: Generic RISC-V Virtual Machine
# -m 2G: 2GB RAM
# -smp 4: 4 CPUs
# -nographic: No GUI, output to console
# -bios: OpenSBI firmware (or U-Boot if SPL is used, but here we use OpenSBI -> U-Boot)
# -kernel: U-Boot binary (OpenSBI jumps to this)
# -device loader: Load Linux kernel at specific address (optional, usually U-Boot loads it)
# But for standard boot flow:
# QEMU -> OpenSBI -> U-Boot -> Linux

# Note: We are using -bios default (OpenSBI built-in) or our own?
# If we use our own OpenSBI, we pass it as -bios.
# However, U-Boot is often loaded as the "kernel" payload for OpenSBI.

# Correct QEMU invocation for OpenSBI + U-Boot:
"${QEMU_BIN}" \
    -M virt \
    -m 2G \
    -smp 4 \
    -nographic \
    -bios "${OPENSBI_BIN}" \
    -device loader,file="${UBOOT_BIN}",addr=0x80200000 \
    -drive file="${ROOTFS_IMAGE}",format=raw,id=hd0 \
    -device virtio-blk-device,drive=hd0 \
    -netdev user,id=net0 \
    -device virtio-net-device,netdev=net0

# Alternative: If U-Boot was built with OpenSBI integrated (SPL), we might just use -kernel u-boot.bin
# But we built OpenSBI generic and U-Boot S-mode.
# The standard way: -bios opensbi -kernel u-boot (but u-boot is S-mode payload)
