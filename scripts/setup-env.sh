#!/bin/bash
# Setup environment for RISC-V QEMU Boot Chain project
# This script installs all necessary dependencies for Ubuntu 24.04

set -e

echo "========================================="
echo "RISC-V QEMU Boot Chain - Environment Setup"
echo "========================================="
echo ""

# Check if running on Ubuntu 24.04
if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [ "$ID" != "ubuntu" ] || [ "$VERSION_ID" != "24.04" ]; then
        echo "Warning: This script is designed for Ubuntu 24.04"
        echo "Current OS: $ID $VERSION_ID"
        read -p "Continue anyway? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
fi

echo "Updating package lists..."
sudo apt-get update

echo ""
echo "Installing basic build tools..."
sudo apt-get install -y \
    build-essential \
    git \
    wget \
    curl \
    python3 \
    python3-pip \
    bc \
    cpio \
    flex \
    bison \
    libssl-dev \
    libelf-dev \
    libncurses-dev \
    device-tree-compiler

echo ""
echo "Installing RISC-V cross-compilation toolchain..."
sudo apt-get install -y \
    gcc-riscv64-linux-gnu \
    g++-riscv64-linux-gnu \
    binutils-riscv64-linux-gnu \
    gdb-multiarch

echo ""
echo "Installing QEMU build dependencies..."
sudo apt-get install -y \
    libglib2.0-dev \
    libpixman-1-dev \
    libfdt-dev \
    zlib1g-dev \
    ninja-build \
    pkg-config \
    libslirp-dev \
    libcap-ng-dev \
    libattr1-dev

echo ""
echo "Verifying installations..."

# Check RISC-V toolchain
if command -v riscv64-linux-gnu-gcc &> /dev/null; then
    echo "✓ RISC-V GCC: $(riscv64-linux-gnu-gcc --version | head -n1)"
else
    echo "✗ RISC-V GCC not found"
    exit 1
fi

# Check Python
if command -v python3 &> /dev/null; then
    echo "✓ Python: $(python3 --version)"
else
    echo "✗ Python3 not found"
    exit 1
fi

# Check git
if command -v git &> /dev/null; then
    echo "✓ Git: $(git --version)"
else
    echo "✗ Git not found"
    exit 1
fi

# Check ninja
if command -v ninja &> /dev/null; then
    echo "✓ Ninja: $(ninja --version)"
else
    echo "✗ Ninja not found"
    exit 1
fi

echo ""
echo "========================================="
echo "Environment setup completed successfully!"
echo "========================================="
echo ""
echo "Next steps:"
echo "  1. Initialize Git submodules: git submodule update --init --recursive"
echo "  2. Source toolchain environment: source scripts/toolchain-env.sh"
echo "  3. Build QEMU: ./scripts/build-qemu.sh"
echo "  4. Build all components: ./scripts/build-all.sh"
echo ""
