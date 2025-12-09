#!/bin/bash
# Build all components for RISC-V QEMU boot flow
# Usage: build_all.sh [--optee]
set -e

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
            echo "  --optee  Build with OP-TEE support"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

echo "========================================"
echo "  RISC-V QEMU Boot Flow - Full Build"
if [ "${OPTEE_MODE}" = true ]; then
    echo "  (with OP-TEE support)"
fi
echo "========================================"
echo ""

if [ "${OPTEE_MODE}" = true ]; then
    echo "Build order:"
    echo "  1. QEMU     (emulator)"
    echo "  2. OP-TEE   (secure world OS)"
    echo "  3. OpenSBI  (M-mode firmware with SPD)"
    echo "  4. U-Boot   (SPL + proper)"
    echo "  5. Linux    (kernel with TEE driver)"
    echo "  6. Buildroot (rootfs with xtest)"
else
    echo "Build order:"
    echo "  1. QEMU     (emulator)"
    echo "  2. OpenSBI  (M-mode firmware)"
    echo "  3. U-Boot   (SPL + proper)"
    echo "  4. Linux    (kernel)"
    echo "  5. Buildroot (rootfs)"
fi
echo ""

START_TIME=$(date +%s)

echo "[1/6] Building QEMU..."
"${SCRIPT_DIR}/build_qemu.sh"
echo ""

if [ "${OPTEE_MODE}" = true ]; then
    echo "[2/6] Building OP-TEE OS..."
    "${SCRIPT_DIR}/build_optee.sh"
    echo ""
    
    echo "[3/6] Building OpenSBI (with OP-TEE SPD)..."
    "${SCRIPT_DIR}/build_opensbi.sh" --optee
    echo ""
    
    echo "[4/6] Building U-Boot (SPL + proper)..."
    "${SCRIPT_DIR}/build_uboot.sh"
    echo ""
    
    echo "[5/6] Building Linux Kernel (with TEE driver)..."
    "${SCRIPT_DIR}/build_linux.sh" --optee
    echo ""
    
    echo "[6/6] Building Buildroot rootfs (with xtest)..."
    "${SCRIPT_DIR}/build_buildroot.sh" --optee
    echo ""
else
    echo "[2/5] Building OpenSBI..."
    "${SCRIPT_DIR}/build_opensbi.sh"
    echo ""
    
    echo "[3/5] Building U-Boot (SPL + proper)..."
    "${SCRIPT_DIR}/build_uboot.sh"
    echo ""
    
    echo "[4/5] Building Linux Kernel..."
    "${SCRIPT_DIR}/build_linux.sh"
    echo ""
    
    echo "[5/5] Building Buildroot rootfs..."
    "${SCRIPT_DIR}/build_buildroot.sh"
    echo ""
fi

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))

echo "========================================"
echo "  Build Complete!"
echo "========================================"
echo ""
echo "Elapsed time: ${ELAPSED} seconds"
echo ""
echo "Artifacts:"
echo "  QEMU:      ${QEMU_SRC}/build/qemu-system-riscv64"
if [ "${OPTEE_MODE}" = true ]; then
    echo "  OP-TEE:    ${BUILD_DIR}/optee/core/tee.bin"
fi
echo "  OpenSBI:   ${OPENSBI_BUILD}/platform/generic/firmware/fw_dynamic.bin"
echo "  U-Boot SPL:${UBOOT_BUILD}/spl/u-boot-spl.bin"
echo "  U-Boot FIT:${UBOOT_BUILD}/u-boot.itb"
echo "  Linux:     ${LINUX_BUILD}/arch/riscv/boot/Image"
echo "  Rootfs:    ${ROOTFS_BUILD}/images/rootfs.cpio"
echo ""
if [ "${OPTEE_MODE}" = true ]; then
    echo "Run: ./scripts/run_qemu.sh --optee"
else
    echo "Run: ./scripts/run_qemu.sh"
fi
