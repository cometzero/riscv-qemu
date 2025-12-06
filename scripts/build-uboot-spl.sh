#!/bin/bash
# Build U-Boot with SPL support for QEMU RISC-V 64-bit
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Building U-Boot with SPL for QEMU RISC-V 64-bit${NC}"

# Navigate to U-Boot source
cd "$PROJECT_ROOT/sources/u-boot"

# Clean previous build
echo -e "${YELLOW}Cleaning previous build...${NC}"
make CROSS_COMPILE=riscv64-linux-gnu- mrproper || true

# Configure for QEMU RISC-V 64-bit with SPL
echo -e "${YELLOW}Configuring U-Boot with SPL...${NC}"
make CROSS_COMPILE=riscv64-linux-gnu- qemu-riscv64_spl_defconfig

# Build U-Boot and SPL
echo -e "${YELLOW}Building U-Boot and SPL...${NC}"
make CROSS_COMPILE=riscv64-linux-gnu- -j$(nproc)

# Verify output files
echo -e "${GREEN}Verifying build output...${NC}"
if [ ! -f spl/u-boot-spl.bin ]; then
    echo -e "${YELLOW}Error: SPL binary not found!${NC}"
    exit 1
fi

if [ ! -f u-boot.bin ]; then
    echo -e "${YELLOW}Error: U-Boot binary not found!${NC}"
    exit 1
fi

# Create build output directory
mkdir -p "$PROJECT_ROOT/build/u-boot/spl"

# Copy binaries to build directory
echo -e "${YELLOW}Copying binaries to build directory...${NC}"
cp spl/u-boot-spl.bin "$PROJECT_ROOT/build/u-boot/spl/"
cp u-boot.bin "$PROJECT_ROOT/build/u-boot/"
cp u-boot "$PROJECT_ROOT/build/u-boot/"

# Show sizes
echo -e "${GREEN}Build complete!${NC}"
echo ""
echo "SPL binary:"
ls -lh spl/u-boot-spl.bin
SPL_SIZE=$(stat -c%s spl/u-boot-spl.bin)
echo "SPL size: $SPL_SIZE bytes"

if [ $SPL_SIZE -lt 65536 ]; then
    echo -e "${GREEN}✓ SPL size check PASS (< 64KB)${NC}"
else
    echo -e "${YELLOW}⚠ SPL size check WARNING (>= 64KB)${NC}"
fi

echo ""
echo "U-Boot binary:"
ls -lh u-boot.bin

echo ""
echo -e "${GREEN}Binaries copied to:${NC}"
echo "  - $PROJECT_ROOT/build/u-boot/spl/u-boot-spl.bin"
echo "  - $PROJECT_ROOT/build/u-boot/u-boot.bin"
