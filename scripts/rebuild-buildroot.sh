#!/bin/bash
# Incremental rebuild script for Buildroot
# Usage: ./scripts/rebuild-buildroot.sh

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source the toolchain environment
source "${SCRIPT_DIR}/toolchain-env.sh"

# Configuration
BUILDROOT_BUILD_DIR="${PROJECT_ROOT}/build/buildroot"
LOG_DIR="${PROJECT_ROOT}/build/logs"
LOG_FILE="${LOG_DIR}/buildroot-rebuild.log"

echo "========================================="
echo "Rebuilding Buildroot (Incremental)"
echo "========================================="
echo "Build Dir: ${BUILDROOT_BUILD_DIR}"
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

if [ ! -d "${BUILDROOT_BUILD_DIR}" ]; then
    echo "ERROR: Build directory not found. Run ./scripts/build-buildroot.sh first."
    exit 1
fi

cd "${BUILDROOT_BUILD_DIR}"

echo "Running make..."
log_exec make -j$(nproc)

if [ $? -ne 0 ]; then
    echo "ERROR: Buildroot rebuild failed. Check ${LOG_FILE}"
    exit 1
fi

echo ""
echo "✓ Buildroot rebuilt successfully"
echo "  Images: ${BUILDROOT_BUILD_DIR}/images/"
echo ""
