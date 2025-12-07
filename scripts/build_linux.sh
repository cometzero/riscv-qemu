#!/bin/bash
# Build Linux kernel for RISC-V QEMU virt
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/env.sh"

COMPONENT="linux"
LOG_FILE="${LOG_DIR}/${COMPONENT}-$(date +%Y%m%d-%H%M%S).log"

echo "=== Building Linux Kernel ==="
echo "Source: ${LINUX_SRC}"
echo "Output: ${LINUX_BUILD}"
echo "Log: ${LOG_FILE}"

mkdir -p "${LINUX_BUILD}" "${LOG_DIR}"

cd "${LINUX_SRC}"

# Configure kernel with defconfig
echo "[Linux] Configuring defconfig..."
make \
    ARCH=${ARCH} \
    CROSS_COMPILE=${CROSS_COMPILE} \
    O="${LINUX_BUILD}" \
    defconfig \
    >> "${LOG_FILE}" 2>&1

# Build kernel Image
echo "[Linux] Building with ${NPROC} jobs..."
make \
    ARCH=${ARCH} \
    CROSS_COMPILE=${CROSS_COMPILE} \
    O="${LINUX_BUILD}" \
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
