#!/bin/bash
# Clean script for OpenSBI
# Usage: ./scripts/clean-opensbi.sh

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Configuration
OPENSBI_BUILD_DIR="${PROJECT_ROOT}/build/opensbi"

echo "Cleaning OpenSBI build..."
if [ -d "${OPENSBI_BUILD_DIR}" ]; then
    rm -rf "${OPENSBI_BUILD_DIR}"
    echo "✓ Removed ${OPENSBI_BUILD_DIR}"
else
    echo "ℹ OpenSBI build directory does not exist"
fi
