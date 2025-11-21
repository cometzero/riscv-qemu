#!/bin/bash
# Master clean script to clean all build artifacts
# Usage: ./scripts/clean.sh

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "========================================="
echo "Cleaning All Build Artifacts"
echo "========================================="
echo ""

read -p "Are you sure you want to delete ALL build artifacts? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Operation cancelled."
    exit 1
fi

echo ""
# Run component clean scripts
"${SCRIPT_DIR}/clean-qemu.sh" 2>/dev/null || rm -rf "${PROJECT_ROOT}/build/qemu"
"${SCRIPT_DIR}/clean-opensbi.sh"
"${SCRIPT_DIR}/clean-uboot.sh"
"${SCRIPT_DIR}/clean-linux.sh"
"${SCRIPT_DIR}/clean-buildroot.sh"

# Clean logs and images
rm -rf "${PROJECT_ROOT}/build/logs"
rm -rf "${PROJECT_ROOT}/build/images"

echo ""
echo "========================================="
echo "All build artifacts cleaned!"
echo "========================================="
echo ""
