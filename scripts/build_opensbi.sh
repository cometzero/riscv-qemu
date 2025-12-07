#!/bin/bash
# Build OpenSBI firmware for RISC-V generic platform
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/env.sh"

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
make \
    PLATFORM=generic \
    CROSS_COMPILE=${CROSS_COMPILE} \
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
