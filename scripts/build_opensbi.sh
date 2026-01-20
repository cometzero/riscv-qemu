#!/bin/bash
# Build OpenSBI firmware for RISC-V generic platform
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/env.sh"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --help|-h)
            echo "Usage: $0"
            echo "  Build OpenSBI firmware for RISC-V QEMU"
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
echo "Log: ${LOG_FILE}"

mkdir -p "${OPENSBI_BUILD}" "${LOG_DIR}"

cd "${OPENSBI_SRC}"

# Build OpenSBI with generic platform
echo "[OpenSBI] Building with ${NPROC} jobs..."

FDT_ARG=""
if [ -n "${OPENSBI_FDT_PATH:-}" ]; then
    if [ ! -f "${OPENSBI_FDT_PATH}" ]; then
        echo "[OpenSBI] ERROR: Custom FDT not found at ${OPENSBI_FDT_PATH}"
        exit 1
    fi
    FDT_ARG="FW_FDT_PATH=${OPENSBI_FDT_PATH}"
fi

make clean O="${OPENSBI_BUILD}" >> "${LOG_FILE}" 2>&1

make \
    PLATFORM=generic \
    CROSS_COMPILE=${CROSS_COMPILE} \
    CC="${CC:-${CROSS_COMPILE}gcc}" \
    ${FDT_ARG} \
    O="${OPENSBI_BUILD}" \
    -j${NPROC} \
    >> "${LOG_FILE}" 2>&1

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
