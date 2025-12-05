#!/bin/bash
# Update Linux Kernel submodule to latest stable tag
# Usage: ./scripts/update-linux.sh [--tag <tag>]

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Configuration
LINUX_SOURCE_DIR="${PROJECT_ROOT}/sources/linux"
LOG_DIR="${PROJECT_ROOT}/build/logs"
LOG_FILE="${LOG_DIR}/linux-update.log"

# Parse arguments
TARGET_TAG=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --tag)
            TARGET_TAG="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--tag <tag>]"
            exit 1
            ;;
    esac
done

echo "========================================="
echo "Updating Linux Kernel Source"
echo "========================================="
echo "Source Dir: ${LINUX_SOURCE_DIR}"
echo "Log:        ${LOG_FILE}"
echo ""

# Ensure log directory exists
mkdir -p "${LOG_DIR}"

# Function to log and execute
log_exec() {
    echo ">>> $@" >> "${LOG_FILE}"
    "$@" >> "${LOG_FILE}" 2>&1
    return $?
}

# Clear previous log
> "${LOG_FILE}"

if [ ! -d "${LINUX_SOURCE_DIR}" ]; then
    echo "ERROR: Linux source directory not found at ${LINUX_SOURCE_DIR}"
    echo "       Run git submodule update --init first."
    exit 1
fi

cd "${LINUX_SOURCE_DIR}"

# Get current version
CURRENT_COMMIT=$(git rev-parse HEAD)
CURRENT_TAG=$(git describe --tags --exact-match 2>/dev/null || echo "no tag")
echo "Current: ${CURRENT_TAG} (${CURRENT_COMMIT:0:8})"

# Fetch latest tags
echo "Fetching latest tags..."
log_exec git fetch --tags

# Determine target tag
if [ -z "${TARGET_TAG}" ]; then
    # Get latest stable tag (vX.X.X format, excluding -rc versions)
    # Linux uses vX.Y or vX.Y.Z format
    TARGET_TAG=$(git tag -l 'v[0-9]*' | grep -E '^v[0-9]+\.[0-9]+(\.[0-9]+)?$' | sort -V | tail -1)
    if [ -z "${TARGET_TAG}" ]; then
        echo "ERROR: Could not determine latest stable tag"
        exit 1
    fi
fi

echo "Target:  ${TARGET_TAG}"

# Check if already at target
TARGET_COMMIT=$(git rev-parse "${TARGET_TAG}")
if [ "${CURRENT_COMMIT}" = "${TARGET_COMMIT}" ]; then
    echo ""
    echo "✓ Linux Kernel is already at ${TARGET_TAG}"
    exit 0
fi

# Checkout target tag
echo "Checking out ${TARGET_TAG}..."
log_exec git checkout "${TARGET_TAG}"

NEW_COMMIT=$(git rev-parse HEAD)

echo ""
echo "✓ Linux Kernel updated successfully"
echo "  Previous: ${CURRENT_TAG} (${CURRENT_COMMIT:0:8})"
echo "  Current:  ${TARGET_TAG} (${NEW_COMMIT:0:8})"
echo ""
echo "Note: Run ./scripts/build-linux.sh to rebuild the kernel"
