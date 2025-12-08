#!/bin/bash
# Build minimal Buildroot rootfs for RISC-V QEMU using external toolchain
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/env.sh"

COMPONENT="buildroot"
LOG_FILE="${LOG_DIR}/${COMPONENT}-$(date +%Y%m%d-%H%M%S).log"

echo "=== Building Buildroot Rootfs ==="
echo "Source: ${BUILDROOT_SRC}"
echo "Output: ${ROOTFS_BUILD}"
echo "Log: ${LOG_FILE}"

mkdir -p "${ROOTFS_BUILD}" "${LOG_DIR}"

cd "${BUILDROOT_SRC}"

# Create minimal config with external toolchain
cat > "${ROOTFS_BUILD}/.config" << 'EOF'
# Target architecture
BR2_riscv=y
BR2_RISCV_64=y
BR2_RISCV_ABI_LP64D=y

# Use external toolchain from host
BR2_TOOLCHAIN_EXTERNAL=y
BR2_TOOLCHAIN_EXTERNAL_DOWNLOAD=y
BR2_TOOLCHAIN_EXTERNAL_BOOTLIN=y
BR2_TOOLCHAIN_EXTERNAL_BOOTLIN_RISCV64_GLIBC_STABLE=y

# System configuration
BR2_TARGET_GENERIC_HOSTNAME="buildroot"
BR2_TARGET_GENERIC_ISSUE="Welcome to RISC-V Buildroot"
BR2_SYSTEM_DHCP="eth0"
BR2_TARGET_GENERIC_GETTY=y
BR2_TARGET_GENERIC_GETTY_PORT="console"

# Init system
BR2_INIT_BUSYBOX=y

# Root filesystem - CPIO for initramfs
BR2_TARGET_ROOTFS_CPIO=y
BR2_TARGET_ROOTFS_CPIO_GZIP=y

# No kernel (built separately)
BR2_LINUX_KERNEL=n
EOF

echo "[Buildroot] Using minimal external toolchain config..."
make O="${ROOTFS_BUILD}" olddefconfig >> "${LOG_FILE}" 2>&1

# Build rootfs
echo "[Buildroot] Building with ${NPROC} jobs..."
make O="${ROOTFS_BUILD}" -j${NPROC} >> "${LOG_FILE}" 2>&1

echo "[Buildroot] Build complete!"

# Check for output
if [ -f "${ROOTFS_BUILD}/images/rootfs.cpio.gz" ]; then
    echo "Rootfs: ${ROOTFS_BUILD}/images/rootfs.cpio.gz"
    echo "[Buildroot] SUCCESS"
    exit 0
elif [ -f "${ROOTFS_BUILD}/images/rootfs.cpio" ]; then
    echo "Rootfs: ${ROOTFS_BUILD}/images/rootfs.cpio"
    echo "[Buildroot] SUCCESS"
    exit 0
else
    echo "[Buildroot] ERROR: Rootfs not found"
    ls -la "${ROOTFS_BUILD}/images/" 2>/dev/null || true
    exit 1
fi
