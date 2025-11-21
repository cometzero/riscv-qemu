#!/bin/bash
# Build script for QEMU from source
# This script configures and builds QEMU with RISC-V support

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source the toolchain environment
source "${SCRIPT_DIR}/toolchain-env.sh"

# Configuration
QEMU_SRC_DIR="${PROJECT_ROOT}/sources/qemu"
QEMU_BUILD_DIR="${PROJECT_ROOT}/build/qemu"
QEMU_INSTALL_DIR="${QEMU_BUILD_DIR}/install"
LOG_DIR="${PROJECT_ROOT}/build/logs"
LOG_FILE="${LOG_DIR}/qemu-build.log"

# Create necessary directories
mkdir -p "${QEMU_BUILD_DIR}"
mkdir -p "${QEMU_INSTALL_DIR}"
mkdir -p "${LOG_DIR}"

echo "========================================="
echo "Building QEMU from source"
echo "========================================="
echo "Source:  ${QEMU_SRC_DIR}"
echo "Build:   ${QEMU_BUILD_DIR}"
echo "Install: ${QEMU_INSTALL_DIR}"
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

# Step 1: Configure QEMU
echo "Step 1: Configuring QEMU..."
cd "${QEMU_BUILD_DIR}"

log_exec "${QEMU_SRC_DIR}/configure" \
    --prefix="${QEMU_INSTALL_DIR}" \
    --target-list=riscv32-softmmu,riscv64-softmmu \
    --enable-slirp \
    --enable-fdt \
    --enable-kvm \
    --enable-virtfs

if [ $? -ne 0 ]; then
    echo "ERROR: QEMU configuration failed. Check ${LOG_FILE}"
    exit 1
fi

echo ""
echo "Step 2: Building QEMU (this may take several minutes)..."
log_exec make -j$(nproc)

if [ $? -ne 0 ]; then
    echo "ERROR: QEMU build failed. Check ${LOG_FILE}"
    exit 1
fi

echo ""
echo "Step 3: Installing QEMU..."
log_exec make install

if [ $? -ne 0 ]; then
    echo "ERROR: QEMU installation failed. Check ${LOG_FILE}"
    exit 1
fi

echo ""
echo "========================================="
echo "QEMU build completed successfully!"
echo "========================================="
echo ""
echo "QEMU binaries installed to: ${QEMU_INSTALL_DIR}/bin"
echo ""
echo "To use the project-built QEMU:"
echo "  source scripts/toolchain-env.sh"
echo ""
echo "Verify installation:"
echo "  ${QEMU_INSTALL_DIR}/bin/qemu-system-riscv64 --version"
echo ""

# Verify the build
"${QEMU_INSTALL_DIR}/bin/qemu-system-riscv64" --version
