#!/bin/bash
# Clean script for Buildroot
# Usage: ./scripts/clean-buildroot.sh

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Configuration
BUILDROOT_BUILD_DIR="${PROJECT_ROOT}/build/buildroot"

echo "Cleaning Buildroot build..."
if [ -d "${BUILDROOT_BUILD_DIR}" ]; then
    rm -rf "${BUILDROOT_BUILD_DIR}"
    echo "✓ Removed ${BUILDROOT_BUILD_DIR}"
else
    echo "ℹ Buildroot build directory does not exist"
fi
