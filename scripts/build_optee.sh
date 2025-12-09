#!/bin/bash
# Build OP-TEE OS for RISC-V QEMU virt platform
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/env.sh"

# OP-TEE source and build directories
OPTEE_SRC="${SOURCES_DIR}/optee_os"
OPTEE_BUILD="${BUILD_DIR}/optee"
OPTEE_CONFIG="${CONFIGS_DIR}/optee/qemu_virt.mk"

# Log file
LOG_FILE="${BUILD_DIR}/logs/optee-$(date +%Y%m%d-%H%M%S).log"
mkdir -p "${BUILD_DIR}/logs"

echo "=== Building OP-TEE OS ==="
echo "Source: ${OPTEE_SRC}"
echo "Output: ${OPTEE_BUILD}"
echo "Config: ${OPTEE_CONFIG}"
echo "Log: ${LOG_FILE}"

# Check source exists
if [ ! -d "${OPTEE_SRC}" ]; then
    echo "ERROR: OP-TEE source not found at ${OPTEE_SRC}"
    echo "Run: git submodule update --init sources/optee_os"
    exit 1
fi

# Create build directory
mkdir -p "${OPTEE_BUILD}"

# Build OP-TEE OS
echo "[OP-TEE] Building for RISC-V QEMU virt..."
(
    cd "${OPTEE_SRC}"
    
    make -j${NPROC} \
        PLATFORM=virt \
        ARCH=riscv \
        CROSS_COMPILE=${CROSS_COMPILE} \
        CFG_TEE_CORE_LOG_LEVEL=3 \
        O="${OPTEE_BUILD}" \
        2>&1
) | tee "${LOG_FILE}"

# Check for output
if [ -f "${OPTEE_BUILD}/core/tee.bin" ]; then
    echo "[OP-TEE] Build complete!"
    echo "Output: ${OPTEE_BUILD}/core/tee.bin"
    ls -la "${OPTEE_BUILD}/core/tee.bin"
    echo "[OP-TEE] SUCCESS"
else
    echo "[OP-TEE] ERROR: tee.bin not found"
    echo "Check log: ${LOG_FILE}"
    exit 1
fi
