#!/bin/bash
# Master build script to build all components in the correct order
# Usage: ./scripts/build-all.sh

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source the toolchain environment
source "${SCRIPT_DIR}/toolchain-env.sh"

echo "========================================="
echo "RISC-V QEMU Boot Chain - Build All"
echo "========================================="
echo "Project Root: ${PROJECT_ROOT}"
echo "Start Time:   $(date)"
echo "========================================="
echo ""

# Function to run a build script
run_build() {
    local script="$1"
    local name="$2"
    
    echo "-----------------------------------------"
    echo "Building ${name}..."
    echo "Script: ${script}"
    echo "-----------------------------------------"
    
    if [ -f "${script}" ]; then
        "${script}"
        if [ $? -ne 0 ]; then
            echo "ERROR: ${name} build failed!"
            exit 1
        fi
    else
        echo "ERROR: Script not found: ${script}"
        exit 1
    fi
    echo ""
}

# 1. Build QEMU (Tooling)
run_build "${SCRIPT_DIR}/build-qemu.sh" "QEMU"

# 2. Build OpenSBI (Firmware) - Required for U-Boot
run_build "${SCRIPT_DIR}/build-opensbi.sh" "OpenSBI"

# 3. Build U-Boot (Bootloader)
run_build "${SCRIPT_DIR}/build-uboot.sh" "U-Boot"

# 4. Build Linux Kernel
run_build "${SCRIPT_DIR}/build-linux.sh" "Linux Kernel"

# 5. Build Buildroot (Root Filesystem)
run_build "${SCRIPT_DIR}/build-buildroot.sh" "Buildroot"

echo "========================================="
echo "All components built successfully!"
echo "========================================="
echo "End Time: $(date)"
echo ""
echo "To run the boot chain:"
echo "  ./scripts/run-qemu.sh"
echo ""
