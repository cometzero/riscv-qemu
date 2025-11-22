#!/bin/bash
# Script to copy all built images to a central directory
# This facilitates easy access and deployment

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Configuration
IMAGES_DIR="${PROJECT_ROOT}/build/images"
QEMU_BUILD_DIR="${PROJECT_ROOT}/build/qemu/install/bin"
OPENSBI_BUILD_DIR="${PROJECT_ROOT}/build/opensbi/platform/generic/firmware"
UBOOT_BUILD_DIR="${PROJECT_ROOT}/build/u-boot"
LINUX_BUILD_DIR="${PROJECT_ROOT}/build/linux/arch/riscv/boot"
BUILDROOT_BUILD_DIR="${PROJECT_ROOT}/build/buildroot/images"

# Create images directory
mkdir -p "${IMAGES_DIR}"

echo "========================================="
echo "Preparing Boot Images"
echo "========================================="
echo "Destination: ${IMAGES_DIR}"
echo ""

# Function to copy and log
copy_image() {
    local src="$1"
    local dst_name="$2"
    
    if [ -f "${src}" ]; then
        cp "${src}" "${IMAGES_DIR}/${dst_name}"
        echo "✓ Copied ${dst_name}"
        echo "  Source: ${src}"
    else
        echo "⚠ Warning: Source file not found: ${src}"
    fi
}

# 1. OpenSBI
copy_image "${OPENSBI_BUILD_DIR}/fw_dynamic.bin" "fw_dynamic.bin"
copy_image "${OPENSBI_BUILD_DIR}/fw_jump.bin" "fw_jump.bin"

# 2. U-Boot
copy_image "${UBOOT_BUILD_DIR}/u-boot.bin" "u-boot.bin"
copy_image "${UBOOT_BUILD_DIR}/u-boot.itb" "u-boot.itb"
copy_image "${UBOOT_BUILD_DIR}/u-boot-spl.bin" "u-boot-spl.bin"

# 3. Linux Kernel
copy_image "${LINUX_BUILD_DIR}/Image" "Image"
copy_image "${LINUX_BUILD_DIR}/dts/qemu-virt.dtb" "qemu-virt.dtb" # Note: DTB might be in a different place depending on kernel version/arch

# 4. Buildroot Rootfs
copy_image "${BUILDROOT_BUILD_DIR}/sdcard.img" "sdcard.img"
copy_image "${BUILDROOT_BUILD_DIR}/rootfs.cpio" "rootfs.cpio"

echo ""
echo "========================================="
echo "Image preparation completed!"
echo "========================================="
echo "List of images in ${IMAGES_DIR}:"
ls -lh "${IMAGES_DIR}"
echo ""
