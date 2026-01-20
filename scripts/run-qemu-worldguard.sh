#!/bin/bash
# Script to run QEMU with WorldGuard extension enabled
# This script is based on run-qemu.sh with WorldGuard option added

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
ROOTFS_IMAGE="${PROJECT_ROOT}/build/buildroot/images/sdcard.img"

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

echo "========================================="
echo "Starting RISC-V QEMU Boot Chain"
echo "WorldGuard: ENABLED"
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

# Run QEMU with WorldGuard enabled
# -M virt,wg=on: Enable WorldGuard extension
"${QEMU_BIN}" \
    -M virt,wg=on \
    -m 2G \
    -smp 4 \
    -nographic \
    -bios "${OPENSBI_BIN}" \
    -kernel "${UBOOT_BIN}" \
    -drive file="${ROOTFS_IMAGE}",format=raw,id=hd0,if=none \
    -device virtio-blk-device,drive=hd0 \
    -netdev user,id=net0 \
    -device virtio-net-device,netdev=net0
