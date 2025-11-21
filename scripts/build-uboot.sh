#!/bin/bash
# Build script for U-Boot bootloader
# This script builds U-Boot for RISC-V QEMU virt machine

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source the toolchain environment
source "${SCRIPT_DIR}/toolchain-env.sh"

# Configuration
UBOOT_SRC_DIR="${PROJECT_ROOT}/sources/u-boot"
UBOOT_BUILD_DIR="${PROJECT_ROOT}/build/u-boot"
OPENSBI_BUILD_DIR="${PROJECT_ROOT}/build/opensbi"
LOG_DIR="${PROJECT_ROOT}/build/logs"
LOG_FILE="${LOG_DIR}/u-boot-build.log"

# Create necessary directories
mkdir -p "${UBOOT_BUILD_DIR}"
mkdir -p "${LOG_DIR}"

echo "========================================="
echo "Building U-Boot for RISC-V QEMU"
echo "========================================="
echo "Source:  ${UBOOT_SRC_DIR}"
echo "Build:   ${UBOOT_BUILD_DIR}"
echo "Log:     ${LOG_FILE}"
echo ""

# Function to log and execute
log_exec() {
    echo ">>> $@" | tee -a "${LOG_FILE}"
    "$@" 2>&1 | tee -a "${LOG_FILE}"
    return ${PIPESTATUS[0]}
}

# Clear previous log
> "${LOG_FILE}"

# Check if OpenSBI is built
if [ ! -f "${OPENSBI_BUILD_DIR}/platform/generic/firmware/fw_dynamic.bin" ]; then
    echo "ERROR: OpenSBI firmware not found. Please build OpenSBI first:"
    echo "  ./scripts/build-opensbi.sh"
    exit 1
fi

# Step 1: Configure U-Boot for QEMU RISC-V
echo "Step 1: Configuring U-Boot for qemu-riscv64_smode..."
cd "${UBOOT_SRC_DIR}"

log_exec make \
    CROSS_COMPILE=${CROSS_COMPILE} \
    O="${UBOOT_BUILD_DIR}" \
    qemu-riscv64_smode_defconfig

if [ $? -ne 0 ]; then
    echo "ERROR: U-Boot configuration failed. Check ${LOG_FILE}"
    exit 1
fi

# Step 2: Build U-Boot
echo ""
echo "Step 2: Building U-Boot (this may take several minutes)..."

log_exec make \
    CROSS_COMPILE=${CROSS_COMPILE} \
    O="${UBOOT_BUILD_DIR}" \
    OPENSBI="${OPENSBI_BUILD_DIR}/platform/generic/firmware/fw_dynamic.bin" \
    -j$(nproc)

if [ $? -ne 0 ]; then
    echo "ERROR: U-Boot build failed. Check ${LOG_FILE}"
    exit 1
fi

echo ""
echo "========================================="
echo "U-Boot build completed successfully!"
echo "========================================="
echo ""
echo "U-Boot binaries:"
echo "  U-Boot: ${UBOOT_BUILD_DIR}/u-boot"
echo "  U-Boot.bin: ${UBOOT_BUILD_DIR}/u-boot.bin"
echo "  U-Boot with OpenSBI: ${UBOOT_BUILD_DIR}/u-boot.bin"
echo ""

# Verify the build
if [ -f "${UBOOT_BUILD_DIR}/u-boot.bin" ]; then
    echo "✓ U-Boot built successfully"
    ls -lh "${UBOOT_BUILD_DIR}/u-boot.bin"
else
    echo "✗ U-Boot binary not found"
    exit 1
fi
