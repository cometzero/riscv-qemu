#!/bin/bash
# Build U-Boot for RISC-V QEMU virt (SPL + proper with OpenSBI)
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
            echo "  Build U-Boot for RISC-V QEMU"
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

COMPONENT="u-boot"
LOG_FILE="${LOG_DIR}/${COMPONENT}-$(date +%Y%m%d-%H%M%S).log"

# OpenSBI firmware path for FIT image
OPENSBI_FW="${OPENSBI_BUILD}/platform/generic/firmware/fw_dynamic.bin"

echo "=== Building U-Boot ==="
echo "Source: ${UBOOT_SRC}"
echo "Output: ${UBOOT_BUILD}"
echo "OpenSBI: ${OPENSBI_FW}"
echo "Log: ${LOG_FILE}"

# Check OpenSBI is built (only if not menuconfig-only mode)
if [ "${DO_MENUCONFIG}" = false ] && [ ! -f "${OPENSBI_FW}" ]; then
    echo "[U-Boot] ERROR: OpenSBI firmware not found. Build OpenSBI first."
    exit 1
fi

mkdir -p "${UBOOT_BUILD}" "${LOG_DIR}"

cd "${UBOOT_SRC}"

# Copy Custom DTS
# echo "[U-Boot] Copying custom DTS..."
# (Assuming DTS is already in sources/u-boot/arch/riscv/dts/qemu_rv64_craft.dts)

# Patch Makefile to include custom DTB (if not already present)
if ! grep -q "qemu_rv64_craft.dtb" "${UBOOT_SRC}/arch/riscv/dts/Makefile"; then
    echo "[U-Boot] Patching arch/riscv/dts/Makefile..."
    sed -i '/dtb-$(CONFIG_TARGET_QEMU_VIRT) +=/ s/$/ qemu_rv64_craft.dtb/' "${UBOOT_SRC}/arch/riscv/dts/Makefile"
fi

# Clean build if requested
if [ "${DO_CLEAN}" = true ]; then
    echo "[U-Boot] Running make clean..."
    make \
        CROSS_COMPILE=${CROSS_COMPILE} \
        CC="${CC:-${CROSS_COMPILE}gcc}" \
        O="${UBOOT_BUILD}" \
        clean \
        >> "${LOG_FILE}" 2>&1
fi

# Determine if we need to run defconfig
RUN_DEFCONFIG=false
if [ "${DO_DEFCONFIG}" = true ]; then
    RUN_DEFCONFIG=true
    echo "[U-Boot] Force defconfig requested..."
elif [ ! -f "${UBOOT_BUILD}/.config" ]; then
    RUN_DEFCONFIG=true
    echo "[U-Boot] No .config found, running defconfig..."
else
    echo "[U-Boot] Using existing .config..."
fi

# Run defconfig if needed
if [ "${RUN_DEFCONFIG}" = true ]; then
    echo "[U-Boot] Configuring qemu_rv64_craft_defconfig..."
    make \
        CROSS_COMPILE=${CROSS_COMPILE} \
        CC="${CC:-${CROSS_COMPILE}gcc}" \
        O="${UBOOT_BUILD}" \
        qemu_rv64_craft_defconfig \
        >> "${LOG_FILE}" 2>&1

    # Apply custom boot configuration
    BOOT_CFG="${CONFIGS_DIR}/u-boot/qemu_boot.cfg"
    if [ -f "${BOOT_CFG}" ]; then
        echo "[U-Boot] Applying custom boot config..."
        cat "${BOOT_CFG}" >> "${UBOOT_BUILD}/.config"
        make CROSS_COMPILE=${CROSS_COMPILE} CC="${CC:-${CROSS_COMPILE}gcc}" O="${UBOOT_BUILD}" olddefconfig >> "${LOG_FILE}" 2>&1
    fi
fi

# Menuconfig mode
if [ "${DO_MENUCONFIG}" = true ]; then
    echo "[U-Boot] Running menuconfig..."
    make \
        CROSS_COMPILE=${CROSS_COMPILE} \
        CC="${CC:-${CROSS_COMPILE}gcc}" \
        O="${UBOOT_BUILD}" \
        menuconfig
    echo "[U-Boot] menuconfig complete. Exiting."
    exit 0
fi

# Build U-Boot with OpenSBI for FIT image
echo "[U-Boot] Building with ${NPROC} jobs..."
make \
    CROSS_COMPILE=${CROSS_COMPILE} \
    CC="${CC:-${CROSS_COMPILE}gcc}" \
    O="${UBOOT_BUILD}" \
    OPENSBI="${OPENSBI_FW}" \
    -j${NPROC} \
    >> "${LOG_FILE}" 2>&1

echo "[U-Boot] Build complete!"
echo "SPL: ${UBOOT_BUILD}/spl/u-boot-spl.bin"
echo "FIT: ${UBOOT_BUILD}/u-boot.itb"

# Verify binaries exist
if [ -f "${UBOOT_BUILD}/spl/u-boot-spl.bin" ] && [ -f "${UBOOT_BUILD}/u-boot.itb" ]; then
    echo "[U-Boot] SUCCESS"
    exit 0
else
    echo "[U-Boot] ERROR: Binaries not found"
    exit 1
fi
