#!/bin/bash
# Orchestrate update of all Git submodules to latest stable versions
# Usage: ./scripts/update-sources.sh [--dry-run] [--component <name>]

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Configuration
LOG_DIR="${PROJECT_ROOT}/build/logs"
VERSION_HISTORY="${PROJECT_ROOT}/docs/version-history.md"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
DATE_ONLY=$(date '+%Y-%m-%d')

# Parse arguments
DRY_RUN=false
COMPONENT=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --component)
            COMPONENT="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--dry-run] [--component <qemu|uboot|opensbi|linux|buildroot>]"
            exit 1
            ;;
    esac
done

echo "========================================="
echo "Updating All Source Components"
echo "========================================="
echo "Timestamp:  ${TIMESTAMP}"
echo "Dry Run:    ${DRY_RUN}"
if [ -n "${COMPONENT}" ]; then
    echo "Component:  ${COMPONENT}"
fi
echo ""

# Ensure directories exist
mkdir -p "${LOG_DIR}"
mkdir -p "$(dirname "${VERSION_HISTORY}")"

# Store version info
declare -A PREV_VERSIONS
declare -A NEW_VERSIONS
declare -A UPDATE_STATUS

# Function to get current version
get_version() {
    local dir="$1"
    if [ -d "$dir" ]; then
        cd "$dir"
        local tag=$(git describe --tags --exact-match 2>/dev/null || echo "")
        local commit=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
        if [ -n "$tag" ]; then
            echo "${tag} (${commit})"
        else
            echo "${commit}"
        fi
        cd - > /dev/null
    else
        echo "not found"
    fi
}

# Function to update component
update_component() {
    local name="$1"
    local script="$2"
    
    echo "----------------------------------------"
    echo "Updating ${name}..."
    echo "----------------------------------------"
    
    # Get previous version
    local source_dir="${PROJECT_ROOT}/sources/${name,,}"
    case "${name}" in
        "U-Boot") source_dir="${PROJECT_ROOT}/sources/u-boot" ;;
        "OpenSBI") source_dir="${PROJECT_ROOT}/sources/opensbi" ;;
    esac
    
    PREV_VERSIONS["${name}"]=$(get_version "${source_dir}")
    
    if [ "${DRY_RUN}" = true ]; then
        echo "[DRY-RUN] Would run: ${script}"
        UPDATE_STATUS["${name}"]="skipped (dry-run)"
        NEW_VERSIONS["${name}"]="${PREV_VERSIONS["${name}"]}"
    else
        if "${SCRIPT_DIR}/${script}"; then
            UPDATE_STATUS["${name}"]="success"
            NEW_VERSIONS["${name}"]=$(get_version "${source_dir}")
        else
            UPDATE_STATUS["${name}"]="failed"
            NEW_VERSIONS["${name}"]="${PREV_VERSIONS["${name}"]}"
        fi
    fi
    echo ""
}

# Define components
declare -A COMPONENTS=(
    ["QEMU"]="update-qemu.sh"
    ["U-Boot"]="update-uboot.sh"
    ["OpenSBI"]="update-opensbi.sh"
    ["Linux"]="update-linux.sh"
    ["Buildroot"]="update-buildroot.sh"
)

# Update components
if [ -n "${COMPONENT}" ]; then
    case "${COMPONENT}" in
        qemu) update_component "QEMU" "update-qemu.sh" ;;
        uboot) update_component "U-Boot" "update-uboot.sh" ;;
        opensbi) update_component "OpenSBI" "update-opensbi.sh" ;;
        linux) update_component "Linux" "update-linux.sh" ;;
        buildroot) update_component "Buildroot" "update-buildroot.sh" ;;
        *)
            echo "ERROR: Unknown component: ${COMPONENT}"
            echo "Valid components: qemu, uboot, opensbi, linux, buildroot"
            exit 1
            ;;
    esac
else
    for name in "QEMU" "U-Boot" "OpenSBI" "Linux" "Buildroot"; do
        update_component "${name}" "${COMPONENTS[${name}]}"
    done
fi

# Print summary
echo "========================================="
echo "Update Summary"
echo "========================================="
printf "%-12s %-25s %-25s %-10s\n" "Component" "Previous" "Current" "Status"
printf "%-12s %-25s %-25s %-10s\n" "---------" "--------" "-------" "------"
for name in "QEMU" "U-Boot" "OpenSBI" "Linux" "Buildroot"; do
    if [ -n "${UPDATE_STATUS[$name]}" ]; then
        printf "%-12s %-25s %-25s %-10s\n" \
            "${name}" \
            "${PREV_VERSIONS[$name]:-N/A}" \
            "${NEW_VERSIONS[$name]:-N/A}" \
            "${UPDATE_STATUS[$name]:-N/A}"
    fi
done
echo ""

# Update version history file (if not dry-run)
if [ "${DRY_RUN}" = false ]; then
    echo "Recording version history..."
    
    # Create header if file doesn't exist
    if [ ! -f "${VERSION_HISTORY}" ]; then
        cat > "${VERSION_HISTORY}" << 'EOF'
# Version History

This document tracks the versions of all source components used in the project.

## Update Log

EOF
    fi
    
    # Append update entry
    {
        echo "### ${DATE_ONLY}"
        echo ""
        echo "| Component | Previous | Current | Status |"
        echo "|-----------|----------|---------|--------|"
        for name in "QEMU" "U-Boot" "OpenSBI" "Linux" "Buildroot"; do
            if [ -n "${UPDATE_STATUS[$name]}" ]; then
                echo "| ${name} | ${PREV_VERSIONS[$name]:-N/A} | ${NEW_VERSIONS[$name]:-N/A} | ${UPDATE_STATUS[$name]} |"
            fi
        done
        echo ""
    } >> "${VERSION_HISTORY}"
    
    echo "✓ Version history updated: ${VERSION_HISTORY}"
fi

echo ""
echo "========================================="
echo "Next Steps"
echo "========================================="
echo "1. Review changes in each source directory"
echo "2. Run ./scripts/build-all.sh to rebuild all components"
echo "3. Run ./scripts/run-qemu.sh to verify boot chain"
echo "4. Commit updated submodule references if successful"
echo ""
