#!/bin/bash
# Build QEMU for RISC-V virt machine
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/env.sh"

COMPONENT="qemu"
LOG_FILE="${LOG_DIR}/${COMPONENT}-$(date +%Y%m%d-%H%M%S).log"

echo "=== Building QEMU ==="
echo "Source: ${QEMU_SRC}"
echo "Output: ${QEMU_BUILD}"
echo "Log: ${LOG_FILE}"

mkdir -p "${QEMU_BUILD}" "${LOG_DIR}"

cd "${QEMU_SRC}"

# QEMU must use native compiler, not cross-compiler
unset CC

# Configure QEMU (only RISC-V softmmu target)
echo "[QEMU] Configuring..."
if [ ! -f "${QEMU_BUILD}/config-host.mak" ]; then
    ./configure \
        --prefix="${QEMU_BUILD}/install" \
        --target-list=riscv64-softmmu \
        --enable-virtfs \
        --disable-werror \
        >> "${LOG_FILE}" 2>&1
fi

# Build
echo "[QEMU] Building with ${NPROC} jobs..."
make -j${NPROC} >> "${LOG_FILE}" 2>&1

echo "[QEMU] Build complete!"
echo "Binary: ${QEMU_SRC}/build/qemu-system-riscv64"

# Verify binary exists
if [ -f "${QEMU_SRC}/build/qemu-system-riscv64" ]; then
    echo "[QEMU] SUCCESS"
    exit 0
else
    echo "[QEMU] ERROR: Binary not found"
    exit 1
fi
