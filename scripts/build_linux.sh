#!/bin/bash
# Build Linux kernel for RISC-V QEMU virt
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/env.sh"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --help|-h)
            echo "Usage: $0"
            echo "  Build Linux kernel for RISC-V QEMU"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

COMPONENT="linux"
LOG_FILE="${LOG_DIR}/${COMPONENT}-$(date +%Y%m%d-%H%M%S).log"

echo "=== Building Linux Kernel ==="
echo "Source: ${LINUX_SRC}"
echo "Output: ${LINUX_BUILD}"
echo "Log: ${LOG_FILE}"

mkdir -p "${LINUX_BUILD}" "${LOG_DIR}"

cd "${LINUX_SRC}"

# Configure kernel with Custom defconfig
echo "[Linux] Configuring qemu_rv64_craft_defconfig..."
make \
    ARCH=${ARCH} \
    CROSS_COMPILE=${CROSS_COMPILE} \
    CC="${CC:-${CROSS_COMPILE}gcc}" \
    O="${LINUX_BUILD}" \
    qemu_rv64_craft_defconfig \
    >> "${LOG_FILE}" 2>&1

# Build kernel Image only (no modules)
echo "[Linux] Building Image with ${NPROC} jobs..."
make \
    ARCH=${ARCH} \
    CROSS_COMPILE=${CROSS_COMPILE} \
    CC="${CC:-${CROSS_COMPILE}gcc}" \
    O="${LINUX_BUILD}" \
    Image \
    -j${NPROC} \
    >> "${LOG_FILE}" 2>&1

echo "[Linux] Build complete!"
echo "Image: ${LINUX_BUILD}/arch/riscv/boot/Image"

# Verify binary exists
if [ -f "${LINUX_BUILD}/arch/riscv/boot/Image" ]; then
    echo "[Linux] SUCCESS"
    exit 0
else
    echo "[Linux] ERROR: Image not found"
    exit 1
fi
