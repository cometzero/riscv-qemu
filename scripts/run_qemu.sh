#!/bin/bash
# Run QEMU with RISC-V virt machine and full boot chain
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/env.sh"

# QEMU binary location
QEMU_BIN="${QEMU_SRC}/build/qemu-system-riscv64"

# Boot images
SPL_BIN="${UBOOT_BUILD}/spl/u-boot-spl.bin"
FIT_BIN="${UBOOT_BUILD}/u-boot.itb"

# Configuration
MACHINE="virt"
MEMORY="256M"
FIT_ADDR="0x80200000"

echo "=== RISC-V QEMU Boot ==="
echo "QEMU: ${QEMU_BIN}"
echo "SPL:  ${SPL_BIN}"
echo "FIT:  ${FIT_BIN}"
echo ""

# Check files exist
if [ ! -f "${QEMU_BIN}" ]; then
    echo "ERROR: QEMU binary not found. Run ./scripts/build_qemu.sh first."
    exit 1
fi

if [ ! -f "${SPL_BIN}" ]; then
    echo "ERROR: U-Boot SPL not found. Run ./scripts/build_uboot.sh first."
    exit 1
fi

if [ ! -f "${FIT_BIN}" ]; then
    echo "ERROR: U-Boot FIT image not found. Run ./scripts/build_uboot.sh first."
    exit 1
fi

echo "Starting QEMU..."
echo "Exit: Ctrl+A then X"
echo ""

exec "${QEMU_BIN}" \
    -M ${MACHINE} \
    -m ${MEMORY} \
    -nographic \
    -bios "${SPL_BIN}" \
    -device loader,file="${FIT_BIN}",addr=${FIT_ADDR}
