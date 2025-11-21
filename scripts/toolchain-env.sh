#!/bin/bash
# Environment setup for RISC-V toolchain and project-built QEMU
# Source this file before building or running components

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# RISC-V toolchain configuration
export CROSS_COMPILE=riscv64-linux-gnu-
export ARCH=riscv

# Add project-built QEMU to PATH (if it exists)
QEMU_BIN_DIR="${PROJECT_ROOT}/build/qemu/install/bin"
if [ -d "$QEMU_BIN_DIR" ]; then
    export PATH="${QEMU_BIN_DIR}:${PATH}"
    echo "✓ Project QEMU added to PATH: ${QEMU_BIN_DIR}"
else
    echo "ℹ Project QEMU not yet built (${QEMU_BIN_DIR})"
fi

# Set number of parallel jobs for builds
export MAKEFLAGS="-j$(nproc)"

# Display environment info
echo ""
echo "========================================="
echo "RISC-V Toolchain Environment"
echo "========================================="
echo "Project Root:    ${PROJECT_ROOT}"
echo "Cross Compiler:  ${CROSS_COMPILE}gcc"
echo "Architecture:    ${ARCH}"
echo "Parallel Jobs:   $(nproc)"
echo ""

# Verify toolchain is available
if command -v ${CROSS_COMPILE}gcc &> /dev/null; then
    echo "✓ RISC-V Toolchain: $(${CROSS_COMPILE}gcc --version | head -n1)"
else
    echo "✗ RISC-V Toolchain not found!"
    echo "  Please run: ./scripts/setup-env.sh"
    return 1
fi

# Check for QEMU
if command -v qemu-system-riscv64 &> /dev/null; then
    QEMU_VERSION=$(qemu-system-riscv64 --version | head -n1)
    QEMU_PATH=$(which qemu-system-riscv64)
    echo "✓ QEMU: ${QEMU_VERSION}"
    echo "  Path: ${QEMU_PATH}"
else
    echo "ℹ QEMU not yet available in PATH"
fi

echo "========================================="
echo ""
