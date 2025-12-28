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

# Compile Custom DTS
DTS_FILE="${OPENSBI_SRC}/platform/generic/qemu_rv64_craft.dts"
DTB_FILE="${BUILD_DIR}/dts/qemu_rv64_craft.dtb"
mkdir -p "$(dirname "${DTB_FILE}")"

if [ -f "${DTS_FILE}" ]; then
    echo "[OpenSBI] Compiling custom DTB: ${DTS_FILE}"
    dtc -I dts -O dtb -o "${DTB_FILE}" "${DTS_FILE}"
else
    echo "[OpenSBI] ERROR: Custom DTS not found at ${DTS_FILE}"
    exit 1
fi

# Standard build with Custom FDT
make \
    PLATFORM=generic \
    CROSS_COMPILE=${CROSS_COMPILE} \
    FW_FDT_PATH="${DTB_FILE}" \
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
