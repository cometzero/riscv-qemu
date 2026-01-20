#!/bin/bash
# Script to run QEMU with U-Boot SPL boot chain and WorldGuard extension
# Boot sequence: SPL → OpenSBI → U-Boot Proper → Linux

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source the toolchain environment
source "${SCRIPT_DIR}/toolchain-env.sh"

# Paths to components
QEMU_BIN="${PROJECT_ROOT}/build/qemu/install/bin/qemu-system-riscv64"
SPL_BIN="${PROJECT_ROOT}/build/u-boot/spl/u-boot-spl.bin"
UBOOT_BIN="${PROJECT_ROOT}/build/u-boot/u-boot.bin"
KERNEL_IMAGE="${PROJECT_ROOT}/build/linux/arch/riscv/boot/Image"
ROOTFS_IMAGE="${PROJECT_ROOT}/build/buildroot/images/sdcard.img"
DTB_FILE="${PROJECT_ROOT}/dts/qemu-virt-worldguard.dtb"

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
check_file "${SPL_BIN}"
check_file "${KERNEL_IMAGE}"

# Optional: Check for DTB (use default if not found)
if [ ! -f "${DTB_FILE}" ]; then
    echo "WARNING: Custom DTB not found: ${DTB_FILE}"
    echo "Using QEMU default DTB (no WorldGuard nodes)"
    DTB_OPTION=""
else
    DTB_OPTION="-dtb ${DTB_FILE}"
fi

echo "========================================="
echo "Starting RISC-V QEMU Boot Chain (SPL)"
echo "WorldGuard: ENABLED"
echo "========================================="
echo "QEMU:      ${QEMU_BIN}"
echo "SPL:       ${SPL_BIN}"
echo "U-Boot:    ${UBOOT_BIN}"
echo "Kernel:    ${KERNEL_IMAGE}"
echo "DTB:       ${DTB_FILE:-QEMU default}"
echo "========================================="
echo ""
echo "Boot sequence: SPL → OpenSBI → U-Boot → Linux"
echo "Press Ctrl+A, X to exit QEMU"
echo ""

# Run QEMU with SPL as bios
# -M virt,wg=on: Enable WorldGuard extension
# -bios: Use U-Boot SPL as first-stage bootloader
# SPL will load OpenSBI, which loads U-Boot Proper, which boots Linux
"${QEMU_BIN}" \
    -M virt,wg=on \
    -m 2G \
    -smp 4 \
    -nographic \
    -bios "${SPL_BIN}" \
    -kernel "${KERNEL_IMAGE}" \
    ${DTB_OPTION}
