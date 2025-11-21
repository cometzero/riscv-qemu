#!/bin/bash
# Clean script for Linux Kernel
# Usage: ./scripts/clean-linux.sh

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Configuration
LINUX_BUILD_DIR="${PROJECT_ROOT}/build/linux"

echo "Cleaning Linux Kernel build..."
if [ -d "${LINUX_BUILD_DIR}" ]; then
    rm -rf "${LINUX_BUILD_DIR}"
    echo "✓ Removed ${LINUX_BUILD_DIR}"
else
    echo "ℹ Linux build directory does not exist"
fi
