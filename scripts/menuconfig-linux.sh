#!/bin/bash
# Helper script to run menuconfig for Linux Kernel
# Usage: ./scripts/menuconfig-linux.sh

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source the toolchain environment
source "${SCRIPT_DIR}/toolchain-env.sh"

# Configuration
LINUX_BUILD_DIR="${PROJECT_ROOT}/build/linux"

if [ ! -d "${LINUX_BUILD_DIR}" ]; then
    echo "ERROR: Build directory not found. Run ./scripts/build-linux.sh first."
    exit 1
fi

echo "Running Linux menuconfig..."
cd "${LINUX_BUILD_DIR}"
make ARCH=riscv CROSS_COMPILE=${CROSS_COMPILE} menuconfig

echo ""
echo "Configuration saved to ${LINUX_BUILD_DIR}/.config"
echo "To save as defconfig: make ARCH=riscv savedefconfig"
echo ""
