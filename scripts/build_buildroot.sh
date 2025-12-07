#!/bin/bash
# Build Buildroot rootfs for RISC-V QEMU
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/env.sh"

COMPONENT="buildroot"
LOG_FILE="${LOG_DIR}/${COMPONENT}-$(date +%Y%m%d-%H%M%S).log"

BUILDROOT_DEFCONFIG="${CONFIGS_DIR}/buildroot/qemu_riscv64_minimal.defconfig"

echo "=== Building Buildroot Rootfs ==="
echo "Source: ${BUILDROOT_SRC}"
echo "Output: ${ROOTFS_BUILD}"
echo "Config: ${BUILDROOT_DEFCONFIG}"
echo "Log: ${LOG_FILE}"

mkdir -p "${ROOTFS_BUILD}" "${LOG_DIR}"

cd "${BUILDROOT_SRC}"

# Apply defconfig
echo "[Buildroot] Configuring qemu_riscv64_minimal..."
make \
    O="${ROOTFS_BUILD}" \
    BR2_EXTERNAL="${CONFIGS_DIR}/buildroot" \
    qemu_riscv64_defconfig \
    >> "${LOG_FILE}" 2>&1

# Build rootfs
echo "[Buildroot] Building with ${NPROC} jobs (this may take a while)..."
make \
    O="${ROOTFS_BUILD}" \
    -j${NPROC} \
    >> "${LOG_FILE}" 2>&1

echo "[Buildroot] Build complete!"
echo "Rootfs: ${ROOTFS_BUILD}/images/rootfs.cpio"

# Verify rootfs exists
if [ -f "${ROOTFS_BUILD}/images/rootfs.cpio" ] || [ -f "${ROOTFS_BUILD}/images/rootfs.cpio.gz" ]; then
    echo "[Buildroot] SUCCESS"
    exit 0
else
    echo "[Buildroot] ERROR: Rootfs not found"
    exit 1
fi
