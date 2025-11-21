#!/bin/bash
# Helper script to run menuconfig for U-Boot
# Usage: ./scripts/menuconfig-uboot.sh

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source the toolchain environment
source "${SCRIPT_DIR}/toolchain-env.sh"

# Configuration
UBOOT_BUILD_DIR="${PROJECT_ROOT}/build/u-boot"

if [ ! -d "${UBOOT_BUILD_DIR}" ]; then
    echo "ERROR: Build directory not found. Run ./scripts/build-uboot.sh first."
    exit 1
fi

echo "Running U-Boot menuconfig..."
cd "${UBOOT_BUILD_DIR}"
make menuconfig

echo ""
echo "Configuration saved to ${UBOOT_BUILD_DIR}/.config"
echo "To save as defconfig: make savedefconfig"
echo ""
