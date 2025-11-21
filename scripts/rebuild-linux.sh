#!/bin/bash
# Incremental rebuild script for Linux Kernel
# Usage: ./scripts/rebuild-linux.sh

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source the toolchain environment
source "${SCRIPT_DIR}/toolchain-env.sh"

# Configuration
LINUX_BUILD_DIR="${PROJECT_ROOT}/build/linux"
LOG_DIR="${PROJECT_ROOT}/build/logs"
LOG_FILE="${LOG_DIR}/linux-rebuild.log"

echo "========================================="
echo "Rebuilding Linux Kernel (Incremental)"
echo "========================================="
echo "Build Dir: ${LINUX_BUILD_DIR}"
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

if [ ! -d "${LINUX_BUILD_DIR}" ]; then
    echo "ERROR: Build directory not found. Run ./scripts/build-linux.sh first."
    exit 1
fi

cd "${LINUX_BUILD_DIR}"

echo "Running make..."
log_exec make ARCH=riscv CROSS_COMPILE=${CROSS_COMPILE} -j$(nproc)

if [ $? -ne 0 ]; then
    echo "ERROR: Linux rebuild failed. Check ${LOG_FILE}"
    exit 1
fi

echo ""
echo "✓ Linux Kernel rebuilt successfully"
echo "  Image: ${LINUX_BUILD_DIR}/arch/riscv/boot/Image"
echo ""
