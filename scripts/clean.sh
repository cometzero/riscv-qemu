#!/bin/bash
# Clean build artifacts
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/env.sh"

show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --help        Show this help"
    echo "  --logs        Also remove log files"
    echo "  --distclean   Remove entire build directory"
    echo ""
    echo "By default, removes component build outputs but keeps logs."
}

CLEAN_LOGS=false
DISTCLEAN=false

for arg in "$@"; do
    case $arg in
        --help)
            show_help
            exit 0
            ;;
        --logs)
            CLEAN_LOGS=true
            ;;
        --distclean)
            DISTCLEAN=true
            ;;
        *)
            echo "Unknown option: $arg"
            show_help
            exit 1
            ;;
    esac
done

echo "=== Clean Build Artifacts ==="

if [ "$DISTCLEAN" = true ]; then
    echo "Removing entire build directory..."
    rm -rf "${BUILD_DIR}"
    echo "Done."
    exit 0
fi

# Clean component build directories
echo "Cleaning component builds..."
rm -rf "${QEMU_BUILD}"
rm -rf "${UBOOT_BUILD}"
rm -rf "${OPENSBI_BUILD}"
rm -rf "${LINUX_BUILD}"
rm -rf "${ROOTFS_BUILD}"

# Clean source build artifacts (in-tree builds)
if [ -d "${QEMU_SRC}/build" ]; then
    echo "Cleaning QEMU in-tree build..."
    rm -rf "${QEMU_SRC}/build"
fi

if [ "$CLEAN_LOGS" = true ]; then
    echo "Removing logs..."
    rm -rf "${LOG_DIR}"
fi

echo "Clean complete."
