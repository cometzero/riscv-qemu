#!/bin/bash
# Incremental rebuild script for OpenSBI
# Usage: ./scripts/rebuild-opensbi.sh

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source the toolchain environment
source "${SCRIPT_DIR}/toolchain-env.sh"

# Configuration
OPENSBI_SRC_DIR="${PROJECT_ROOT}/sources/opensbi"
OPENSBI_BUILD_DIR="${PROJECT_ROOT}/build/opensbi"
LOG_DIR="${PROJECT_ROOT}/build/logs"
LOG_FILE="${LOG_DIR}/opensbi-rebuild.log"

echo "========================================="
echo "Rebuilding OpenSBI (Incremental)"
echo "========================================="
echo "Build Dir: ${OPENSBI_BUILD_DIR}"
echo "Log:       ${LOG_FILE}"
echo ""

# Function to log and execute
log_exec() {
    echo ">>> $@" >> "${LOG_FILE}"
    "$@" >> "${LOG_FILE}" 2>&1
    return $?
}

# Clear previous log
> "${LOG_FILE}"

if [ ! -d "${OPENSBI_BUILD_DIR}" ]; then
    echo "ERROR: Build directory not found. Run ./scripts/build-opensbi.sh first."
    exit 1
fi

cd "${OPENSBI_SRC_DIR}"

echo "Running make..."
log_exec make \
    CROSS_COMPILE=${CROSS_COMPILE} \
    PLATFORM=generic \
    O="${OPENSBI_BUILD_DIR}" \
    -j$(nproc)

if [ $? -ne 0 ]; then
    echo "ERROR: OpenSBI rebuild failed. Check ${LOG_FILE}"
    exit 1
fi

echo ""
echo "✓ OpenSBI rebuilt successfully"
echo "  Binary: ${OPENSBI_BUILD_DIR}/platform/generic/firmware/fw_dynamic.bin"
echo ""
