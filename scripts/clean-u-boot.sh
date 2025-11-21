#!/bin/bash
# Clean script for U-Boot
# Usage: ./scripts/clean-u-boot.sh

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Configuration
UBOOT_BUILD_DIR="${PROJECT_ROOT}/build/u-boot"

echo "Cleaning U-Boot build..."
if [ -d "${UBOOT_BUILD_DIR}" ]; then
    rm -rf "${UBOOT_BUILD_DIR}"
    echo "✓ Removed ${UBOOT_BUILD_DIR}"
else
    echo "ℹ U-Boot build directory does not exist"
fi
