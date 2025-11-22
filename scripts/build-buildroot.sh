#!/bin/bash
# Build script for Buildroot (Root Filesystem)
# This script builds a minimal rootfs for RISC-V QEMU

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source the toolchain environment
source "${SCRIPT_DIR}/toolchain-env.sh"

# Configuration
BUILDROOT_SRC_DIR="${PROJECT_ROOT}/sources/buildroot"
BUILDROOT_BUILD_DIR="${PROJECT_ROOT}/build/buildroot"
LOG_DIR="${PROJECT_ROOT}/build/logs"
LOG_FILE="${LOG_DIR}/buildroot-build.log"

# Create necessary directories
mkdir -p "${BUILDROOT_BUILD_DIR}"
mkdir -p "${LOG_DIR}"

echo "========================================="
echo "Building Buildroot (Root Filesystem)"
echo "========================================="
echo "Source:  ${BUILDROOT_SRC_DIR}"
echo "Build:   ${BUILDROOT_BUILD_DIR}"
echo "Log:     ${LOG_FILE}"
echo ""

# Function to log and execute (file output only)
log_exec() {
    echo ">>> $@" >> "${LOG_FILE}"
    "$@" >> "${LOG_FILE}" 2>&1
    return $?
}

# Clear previous log
> "${LOG_FILE}"

# Step 1: Configure Buildroot
echo "Step 1: Configuring Buildroot..."
cd "${BUILDROOT_SRC_DIR}"

# Use qemu_riscv64_virt_defconfig as base with BR2_EXTERNAL
# Use custom riscv64_virt_defconfig with BR2_EXTERNAL
log_exec make BR2_EXTERNAL="${PROJECT_ROOT}/configs/buildroot/external" O="${BUILDROOT_BUILD_DIR}" defconfig BR2_DEFCONFIG="${PROJECT_ROOT}/configs/buildroot/riscv64_virt_defconfig"

if [ $? -ne 0 ]; then
    echo "ERROR: Buildroot configuration failed. Check ${LOG_FILE}"
    exit 1
fi

# Step 2: Build Buildroot
echo ""
echo "Step 2: Building Buildroot (this may take 30+ minutes)..."
cd "${BUILDROOT_BUILD_DIR}"

log_exec make -j$(nproc)

if [ $? -ne 0 ]; then
    echo "ERROR: Buildroot build failed. Check ${LOG_FILE}"
    exit 1
fi

echo ""
echo "========================================="
echo "Buildroot build completed successfully!"
echo "========================================="
echo ""
echo "Rootfs images:"
echo "  ext4: ${BUILDROOT_BUILD_DIR}/images/rootfs.ext4"
echo "  cpio: ${BUILDROOT_BUILD_DIR}/images/rootfs.cpio"
echo "  tar:  ${BUILDROOT_BUILD_DIR}/images/rootfs.tar"
echo ""

# Verify the build
if [ -f "${BUILDROOT_BUILD_DIR}/images/sdcard.img" ]; then
    echo "✓ Buildroot sdcard.img built successfully"
    ls -lh "${BUILDROOT_BUILD_DIR}/images/sdcard.img"
else
    echo "✗ Buildroot sdcard.img not found"
    exit 1
fi
