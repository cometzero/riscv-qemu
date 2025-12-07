#!/bin/bash
# Build all components for RISC-V QEMU boot flow
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/env.sh"

echo "========================================"
echo "  RISC-V QEMU Boot Flow - Full Build"
echo "========================================"
echo ""
echo "Build order:"
echo "  1. QEMU     (emulator)"
echo "  2. OpenSBI  (M-mode firmware)"
echo "  3. U-Boot   (SPL + proper)"
echo "  4. Linux    (kernel)"
echo "  5. Buildroot (rootfs)"
echo ""

START_TIME=$(date +%s)

echo "[1/5] Building QEMU..."
"${SCRIPT_DIR}/build_qemu.sh"
echo ""

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
echo "  OpenSBI:   ${OPENSBI_BUILD}/platform/generic/firmware/fw_dynamic.bin"
echo "  U-Boot SPL:${UBOOT_BUILD}/spl/u-boot-spl.bin"
echo "  U-Boot FIT:${UBOOT_BUILD}/u-boot.itb"
echo "  Linux:     ${LINUX_BUILD}/arch/riscv/boot/Image"
echo "  Rootfs:    ${ROOTFS_BUILD}/images/rootfs.cpio"
echo ""
echo "Run: ./scripts/run_qemu.sh"
