#!/bin/bash
# Build Linux kernel for RISC-V QEMU virt
# Usage: build_linux.sh [--optee]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/env.sh"

# Parse arguments
OPTEE_MODE=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --optee)
            OPTEE_MODE=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [--optee]"
            echo "  --optee  Build Linux with OP-TEE TEE driver support"
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
if [ "${OPTEE_MODE}" = true ]; then
    echo "Mode: OP-TEE TEE driver enabled"
fi
echo "Log: ${LOG_FILE}"

mkdir -p "${LINUX_BUILD}" "${LOG_DIR}"

cd "${LINUX_SRC}"

# Copy Custom DTS
# echo "[Linux] Copying custom DTS..."
# (Assuming DTS is already in sources/linux/arch/riscv/boot/dts/qemu/qemu_rv64_craft.dts)

# Create/Update qemu/Makefile
if [ ! -f "${LINUX_SRC}/arch/riscv/boot/dts/qemu/Makefile" ]; then
    echo "dtb-y += qemu_rv64_craft.dtb" > "${LINUX_SRC}/arch/riscv/boot/dts/qemu/Makefile"
else
    if ! grep -q "qemu_rv64_craft.dtb" "${LINUX_SRC}/arch/riscv/boot/dts/qemu/Makefile"; then
        echo "dtb-y += qemu_rv64_craft.dtb" >> "${LINUX_SRC}/arch/riscv/boot/dts/qemu/Makefile"
    fi
fi

# Patch arch/riscv/boot/dts/Makefile to include qemu subdir
if ! grep -q "subdir-y += qemu" "${LINUX_SRC}/arch/riscv/boot/dts/Makefile"; then
    echo "[Linux] Patching arch/riscv/boot/dts/Makefile..."
    echo "subdir-y += qemu" >> "${LINUX_SRC}/arch/riscv/boot/dts/Makefile"
fi

# Configure kernel with Custom defconfig
echo "[Linux] Configuring qemu_rv64_craft_defconfig..."
# cp "${CONFIGS_DIR}/linux/qemu_rv64_craft_defconfig" "${LINUX_SRC}/arch/riscv/configs/"
make \
    ARCH=${ARCH} \
    CROSS_COMPILE=${CROSS_COMPILE} \
    O="${LINUX_BUILD}" \
    qemu_rv64_craft_defconfig \
    >> "${LOG_FILE}" 2>&1

# Apply OP-TEE config fragment if requested
if [ "${OPTEE_MODE}" = true ]; then
    OPTEE_FRAGMENT="${CONFIGS_DIR}/linux/optee.fragment"
    if [ -f "${OPTEE_FRAGMENT}" ]; then
        echo "[Linux] Applying OP-TEE config fragment..."
        # Use merge_config.sh for proper fragment merging
        cd "${LINUX_BUILD}"
        "${LINUX_SRC}/scripts/kconfig/merge_config.sh" -m .config "${OPTEE_FRAGMENT}" \
            >> "${LOG_FILE}" 2>&1
        cd "${LINUX_SRC}"
        make \
            ARCH=${ARCH} \
            CROSS_COMPILE=${CROSS_COMPILE} \
            O="${LINUX_BUILD}" \
            olddefconfig \
            >> "${LOG_FILE}" 2>&1
    else
        echo "[Linux] WARNING: OP-TEE config fragment not found at ${OPTEE_FRAGMENT}"
    fi
fi

# Build kernel Image only (no modules)
echo "[Linux] Building Image with ${NPROC} jobs..."
make \
    ARCH=${ARCH} \
    CROSS_COMPILE=${CROSS_COMPILE} \
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
