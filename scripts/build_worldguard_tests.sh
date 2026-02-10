#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/env.sh"

OVERLAY_DIR="${BUILD_DIR}/rootfs-overlay"
OVERLAY_INITD="${OVERLAY_DIR}/etc/init.d"
OVERLAY_ROOT="${OVERLAY_DIR}/root"

KMOD_SRC_DIR="${RISCV_QEMU_ROOT}/tests/worldguard_linux"
INIT_SCRIPT_SRC="${RISCV_QEMU_ROOT}/configs/rootfs_overlay/etc/init.d/S99worldguard-test"

echo "=== Building WorldGuard Linux/U-mode tests ==="
echo "Kernel build: ${LINUX_BUILD}"
echo "Overlay:      ${OVERLAY_DIR}"

mkdir -p "${OVERLAY_INITD}" "${OVERLAY_ROOT}"

if [ ! -f "${LINUX_BUILD}/.config" ]; then
    echo "[WGTEST] Linux not configured; run ./scripts/build_linux.sh first" >&2
    exit 1
fi

echo "[WGTEST] Ensuring kernel module build prerequisites..."
make -C "${LINUX_SRC}" \
    ARCH=${ARCH} \
    CROSS_COMPILE=${CROSS_COMPILE} \
    CC="${CC:-${CROSS_COMPILE}gcc}" \
    O="${LINUX_BUILD}" \
    modules_prepare

if [ ! -f "${LINUX_BUILD}/Module.symvers" ]; then
    echo "[WGTEST] Building in-tree modules to generate Module.symvers..."
    make -C "${LINUX_SRC}" \
        ARCH=${ARCH} \
        CROSS_COMPILE=${CROSS_COMPILE} \
        CC="${CC:-${CROSS_COMPILE}gcc}" \
        O="${LINUX_BUILD}" \
        -j${NPROC} \
        modules
fi

echo "[WGTEST] Building kernel module..."
make -C "${LINUX_SRC}" \
    ARCH=${ARCH} \
    CROSS_COMPILE=${CROSS_COMPILE} \
    CC="${CC:-${CROSS_COMPILE}gcc}" \
    O="${LINUX_BUILD}" \
    M="${KMOD_SRC_DIR}" \
    modules

echo "[WGTEST] Copying artifacts into overlay..."
install -m 0755 "${INIT_SCRIPT_SRC}" "${OVERLAY_INITD}/S99worldguard-test"
install -m 0644 "${KMOD_SRC_DIR}/wg_smode_memtest.ko" "${OVERLAY_ROOT}/wg_smode_memtest.ko"

echo "[WGTEST] Done. Overlay contents:"
ls -la "${OVERLAY_DIR}" "${OVERLAY_INITD}" "${OVERLAY_ROOT}"
