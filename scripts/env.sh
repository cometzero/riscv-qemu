#!/bin/bash
# Environment setup for RISC-V QEMU boot flow
# Source this file: source scripts/env.sh

# RISC-V target configuration
export ARCH=riscv
# Toolchain
if command -v ccache &> /dev/null; then
    export CROSS_COMPILE="ccache riscv64-linux-gnu-"
else
    export CROSS_COMPILE="riscv64-linux-gnu-"
fi

# Project root directory
export RISCV_QEMU_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Directory paths
export BUILD_DIR="${RISCV_QEMU_ROOT}/build"
export SOURCES_DIR="${RISCV_QEMU_ROOT}/sources"
export CONFIGS_DIR="${RISCV_QEMU_ROOT}/configs"
export SCRIPTS_DIR="${RISCV_QEMU_ROOT}/scripts"

# Build parallelism
export NPROC=$(nproc)

# Component directories
export QEMU_SRC="${SOURCES_DIR}/qemu"
export UBOOT_SRC="${SOURCES_DIR}/u-boot"
export OPENSBI_SRC="${SOURCES_DIR}/opensbi"
export LINUX_SRC="${SOURCES_DIR}/linux"
export BUILDROOT_SRC="${SOURCES_DIR}/buildroot"

# Build output directories
export QEMU_BUILD="${BUILD_DIR}/qemu"
export UBOOT_BUILD="${BUILD_DIR}/u-boot"
export OPENSBI_BUILD="${BUILD_DIR}/opensbi"
export LINUX_BUILD="${BUILD_DIR}/linux"
export ROOTFS_BUILD="${BUILD_DIR}/rootfs"

# Log directory
export LOG_DIR="${BUILD_DIR}/logs"

# Create build directories if needed
mkdir -p "${BUILD_DIR}" "${LOG_DIR}"

echo "[env.sh] Environment configured for RISC-V QEMU boot flow"
echo "  ARCH=${ARCH}"
echo "  CROSS_COMPILE=${CROSS_COMPILE}"
echo "  RISCV_QEMU_ROOT=${RISCV_QEMU_ROOT}"
echo "  NPROC=${NPROC}"
