#!/bin/bash
# Check prerequisites for building RISC-V QEMU boot flow
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Required packages
REQUIRED_PACKAGES=(
    # Build essentials
    "build-essential"
    "git"
    "python3"
    
    # Cross-compiler
    "gcc-riscv64-linux-gnu"
    "g++-riscv64-linux-gnu"
    
    # QEMU build dependencies
    "libglib2.0-dev"
    "libpixman-1-dev"
    "ninja-build"
    "meson"
    
    # Kernel build dependencies
    "flex"
    "bison"
    "libssl-dev"
    "bc"
    "libncurses-dev"
    
    # Buildroot dependencies
    "cpio"
    "unzip"
    "rsync"
    "wget"
)

echo "=== RISC-V QEMU Boot Flow Prerequisites Check ==="
echo ""

MISSING=()

for pkg in "${REQUIRED_PACKAGES[@]}"; do
    if dpkg -s "$pkg" &>/dev/null; then
        echo "[OK] $pkg"
    else
        echo "[MISSING] $pkg"
        MISSING+=("$pkg")
    fi
done

echo ""

if [ ${#MISSING[@]} -eq 0 ]; then
    echo "All prerequisites are installed!"
    
    # Verify cross-compiler
    echo ""
    echo "Cross-compiler version:"
    riscv64-linux-gnu-gcc --version | head -1
    
    exit 0
else
    echo "Missing packages: ${MISSING[*]}"
    echo ""
    echo "Install with:"
    echo "  sudo apt install -y ${MISSING[*]}"
    exit 1
fi
