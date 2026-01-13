#!/bin/bash
# Build Linux kernel for RISC-V QEMU virt
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/env.sh"

# Configuration options
DO_MENUCONFIG=false
DO_DEFCONFIG=false
DO_CLEAN=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --menuconfig)
            DO_MENUCONFIG=true
            shift
            ;;
        --defconfig)
            DO_DEFCONFIG=true
            shift
            ;;
        --clean)
            DO_CLEAN=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo "  Build Linux kernel for RISC-V QEMU"
            echo ""
            echo "Options:"
            echo "  --menuconfig  Run menuconfig only (exit after)"
            echo "  --defconfig   Force run defconfig (even if .config exists)"
            echo "  --clean       Run make clean before building"
            echo "  -h, --help    Show this help message"
            echo ""
            echo "Default behavior:"
            echo "  - If .config exists, skip defconfig"
            echo "  - If .config does not exist, run defconfig"
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

# Clean build if requested
if [ "${DO_CLEAN}" = true ]; then
    echo "[Linux] Running make clean..."
    make \
        ARCH=${ARCH} \
        CROSS_COMPILE=${CROSS_COMPILE} \
        CC="${CC:-${CROSS_COMPILE}gcc}" \
        O="${LINUX_BUILD}" \
        clean \
        >> "${LOG_FILE}" 2>&1
fi

# Determine if we need to run defconfig
RUN_DEFCONFIG=false
if [ "${DO_DEFCONFIG}" = true ]; then
    RUN_DEFCONFIG=true
    echo "[Linux] Force defconfig requested..."
elif [ ! -f "${LINUX_BUILD}/.config" ]; then
    RUN_DEFCONFIG=true
    echo "[Linux] No .config found, running defconfig..."
else
    echo "[Linux] Using existing .config..."
fi

# Run defconfig if needed
if [ "${RUN_DEFCONFIG}" = true ]; then
    echo "[Linux] Configuring qemu_rv64_craft_defconfig..."
    make \
        ARCH=${ARCH} \
        CROSS_COMPILE=${CROSS_COMPILE} \
        CC="${CC:-${CROSS_COMPILE}gcc}" \
        O="${LINUX_BUILD}" \
        qemu_rv64_craft_defconfig \
        >> "${LOG_FILE}" 2>&1
fi

# Menuconfig mode
if [ "${DO_MENUCONFIG}" = true ]; then
    echo "[Linux] Running menuconfig..."
    make \
        ARCH=${ARCH} \
        CROSS_COMPILE=${CROSS_COMPILE} \
        CC="${CC:-${CROSS_COMPILE}gcc}" \
        O="${LINUX_BUILD}" \
        menuconfig
    echo "[Linux] menuconfig complete. Exiting."
    exit 0
fi

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
