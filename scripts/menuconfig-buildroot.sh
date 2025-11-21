#!/bin/bash
# Helper script to run menuconfig for Buildroot
# Usage: ./scripts/menuconfig-buildroot.sh

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source the toolchain environment
source "${SCRIPT_DIR}/toolchain-env.sh"

# Configuration
BUILDROOT_BUILD_DIR="${PROJECT_ROOT}/build/buildroot"

if [ ! -d "${BUILDROOT_BUILD_DIR}" ]; then
    echo "ERROR: Build directory not found. Run ./scripts/build-buildroot.sh first."
    exit 1
fi

echo "Running Buildroot menuconfig..."
cd "${BUILDROOT_BUILD_DIR}"
make menuconfig

echo ""
echo "Configuration saved to ${BUILDROOT_BUILD_DIR}/.config"
echo "To save as defconfig: make savedefconfig"
echo ""
