#!/bin/bash
# Build script for OpenSBI firmware
# This script builds OpenSBI with the generic platform for RISC-V

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source the toolchain environment
source "${SCRIPT_DIR}/toolchain-env.sh"

# Configuration
OPENSBI_SRC_DIR="${PROJECT_ROOT}/sources/opensbi"
OPENSBI_BUILD_DIR="${PROJECT_ROOT}/build/opensbi"
LOG_DIR="${PROJECT_ROOT}/build/logs"
LOG_FILE="${LOG_DIR}/opensbi-build.log"

# Create necessary directories
mkdir -p "${OPENSBI_BUILD_DIR}"
mkdir -p "${LOG_DIR}"

echo "========================================="
echo "Building OpenSBI firmware"
echo "========================================="
echo "Source:  ${OPENSBI_SRC_DIR}"
echo "Build:   ${OPENSBI_BUILD_DIR}"
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

# Step 1: Build OpenSBI
echo "Step 1: Building OpenSBI for RISC-V generic platform..."
cd "${OPENSBI_SRC_DIR}"

log_exec make \
    CROSS_COMPILE=${CROSS_COMPILE} \
    PLATFORM=generic \
    O="${OPENSBI_BUILD_DIR}" \
    -j$(nproc)

if [ $? -ne 0 ]; then
    echo "ERROR: OpenSBI build failed. Check ${LOG_FILE}"
    exit 1
fi

echo ""
echo "========================================="
echo "OpenSBI build completed successfully!"
echo "========================================="
echo ""
echo "OpenSBI firmware binaries:"
echo "  FW_DYNAMIC: ${OPENSBI_BUILD_DIR}/platform/generic/firmware/fw_dynamic.bin"
echo "  FW_DYNAMIC.ELF: ${OPENSBI_BUILD_DIR}/platform/generic/firmware/fw_dynamic.elf"
echo "  FW_JUMP: ${OPENSBI_BUILD_DIR}/platform/generic/firmware/fw_jump.bin"
echo "  FW_JUMP.ELF: ${OPENSBI_BUILD_DIR}/platform/generic/firmware/fw_jump.elf"
echo ""

# Verify the build
if [ -f "${OPENSBI_BUILD_DIR}/platform/generic/firmware/fw_dynamic.bin" ]; then
    echo "✓ OpenSBI fw_dynamic.bin built successfully"
    ls -lh "${OPENSBI_BUILD_DIR}/platform/generic/firmware/fw_dynamic.bin"
else
    echo "✗ OpenSBI fw_dynamic.bin not found"
    exit 1
fi
