#!/bin/bash
# Incremental rebuild script for U-Boot
# Usage: ./scripts/rebuild-uboot.sh

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source the toolchain environment
source "${SCRIPT_DIR}/toolchain-env.sh"

# Configuration
UBOOT_BUILD_DIR="${PROJECT_ROOT}/build/u-boot"
LOG_DIR="${PROJECT_ROOT}/build/logs"
LOG_FILE="${LOG_DIR}/u-boot-rebuild.log"

echo "========================================="
echo "Rebuilding U-Boot (Incremental)"
echo "========================================="
echo "Build Dir: ${UBOOT_BUILD_DIR}"
echo "Log:       ${LOG_FILE}"
echo ""

# Function to log and execute
log_exec() {
    echo ">>> $@" >> "${LOG_FILE}"
    "$@" >> "${LOG_FILE}" 2>&1
    return $?
}

# Clear previous log
> "${LOG_FILE}"

if [ ! -d "${UBOOT_BUILD_DIR}" ]; then
    echo "ERROR: Build directory not found. Run ./scripts/build-uboot.sh first."
    exit 1
fi

cd "${UBOOT_BUILD_DIR}"

echo "Running make..."
log_exec make -j$(nproc)

if [ $? -ne 0 ]; then
    echo "ERROR: U-Boot rebuild failed. Check ${LOG_FILE}"
    exit 1
fi

echo ""
echo "✓ U-Boot rebuilt successfully"
echo "  Binary: ${UBOOT_BUILD_DIR}/u-boot.bin"
echo ""
