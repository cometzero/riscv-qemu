#!/bin/bash
# Build script for Linux kernel
# This script builds the Linux kernel for RISC-V

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source the toolchain environment
source "${SCRIPT_DIR}/toolchain-env.sh"

# Configuration
LINUX_SRC_DIR="${PROJECT_ROOT}/sources/linux"
LINUX_BUILD_DIR="${PROJECT_ROOT}/build/linux"
LOG_DIR="${PROJECT_ROOT}/build/logs"
LOG_FILE="${LOG_DIR}/linux-build.log"

# Create necessary directories
mkdir -p "${LINUX_BUILD_DIR}"
mkdir -p "${LOG_DIR}"

echo "========================================="
echo "Building Linux kernel for RISC-V"
echo "========================================="
echo "Source:  ${LINUX_SRC_DIR}"
echo "Build:   ${LINUX_BUILD_DIR}"
echo "Log:     ${LOG_FILE}"
echo ""

# Function to log and execute
log_exec() {
    echo ">>> $@" >> "${LOG_FILE}"
    "$@" >> "${LOG_FILE}" 2>&1
    return $?
}

# Clear previous log
> "${LOG_FILE}"

# Step 1: Configure Linux kernel
echo "Step 1: Configuring Linux kernel with defconfig..."
cd "${LINUX_SRC_DIR}"

log_exec make \
    ARCH=${ARCH} \
    CROSS_COMPILE=${CROSS_COMPILE} \
    O="${LINUX_BUILD_DIR}" \
    defconfig

if [ $? -ne 0 ]; then
    echo "ERROR: Linux kernel configuration failed. Check ${LOG_FILE}"
    exit 1
fi

# Step 2: Build Linux kernel
echo ""
echo "Step 2: Building Linux kernel (this may take 10-20 minutes)..."

log_exec make \
    ARCH=${ARCH} \
    CROSS_COMPILE=${CROSS_COMPILE} \
    O="${LINUX_BUILD_DIR}" \
    -j$(nproc)

if [ $? -ne 0 ]; then
    echo "ERROR: Linux kernel build failed. Check ${LOG_FILE}"
    exit 1
fi

echo ""
echo "========================================="
echo "Linux kernel build completed successfully!"
echo "========================================="
echo ""
echo "Kernel binaries:"
echo "  Image: ${LINUX_BUILD_DIR}/arch/riscv/boot/Image"
echo "  vmlinux: ${LINUX_BUILD_DIR}/vmlinux"
echo ""

# Verify the build
if [ -f "${LINUX_BUILD_DIR}/arch/riscv/boot/Image" ]; then
    echo "✓ Linux kernel Image built successfully"
    ls -lh "${LINUX_BUILD_DIR}/arch/riscv/boot/Image"
else
    echo "✗ Linux kernel Image not found"
    exit 1
fi
