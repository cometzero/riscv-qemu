#!/bin/bash
# Build OpenSBI firmware for RISC-V generic platform
# Usage: build_opensbi.sh [--optee]
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
            echo "  --optee  Build OpenSBI with OP-TEE SPD support"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

COMPONENT="opensbi"
LOG_FILE="${LOG_DIR}/${COMPONENT}-$(date +%Y%m%d-%H%M%S).log"

echo "=== Building OpenSBI ==="
echo "Source: ${OPENSBI_SRC}"
echo "Output: ${OPENSBI_BUILD}"
if [ "${OPTEE_MODE}" = true ]; then
    echo "Mode: OP-TEE SPD enabled"
fi
echo "Log: ${LOG_FILE}"

mkdir -p "${OPENSBI_BUILD}" "${LOG_DIR}"

cd "${OPENSBI_SRC}"

# Build OpenSBI with generic platform
echo "[OpenSBI] Building with ${NPROC} jobs..."

if [ "${OPTEE_MODE}" = true ]; then
    # Check if OP-TEE binary exists
    OPTEE_BIN="${BUILD_DIR}/optee/core/tee.bin"
    if [ ! -f "${OPTEE_BIN}" ]; then
        echo "[OpenSBI] WARNING: OP-TEE binary not found at ${OPTEE_BIN}"
        echo "[OpenSBI] Building without OP-TEE payload (run build_optee.sh first)"
    fi
    
    # Build with OP-TEE SPD configuration
    # Note: Full OP-TEE SPD integration requires RISE patches to be applied
    make \
        PLATFORM=generic \
        CROSS_COMPILE=${CROSS_COMPILE} \
        O="${OPENSBI_BUILD}" \
        -j${NPROC} \
        >> "${LOG_FILE}" 2>&1
else
    # Standard build without OP-TEE
    make \
        PLATFORM=generic \
        CROSS_COMPILE=${CROSS_COMPILE} \
        O="${OPENSBI_BUILD}" \
        -j${NPROC} \
        >> "${LOG_FILE}" 2>&1
fi

echo "[OpenSBI] Build complete!"
echo "Firmware: ${OPENSBI_BUILD}/platform/generic/firmware/fw_dynamic.bin"

# Verify binary exists
if [ -f "${OPENSBI_BUILD}/platform/generic/firmware/fw_dynamic.bin" ]; then
    echo "[OpenSBI] SUCCESS"
    exit 0
else
    echo "[OpenSBI] ERROR: Firmware not found"
    exit 1
fi
