#!/bin/bash
# Dump QEMU virt machine DTB to DTS for WorldGuard configuration
# Usage: ./scripts/dump-qemu-dtb.sh [output-dir]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

OUTPUT_DIR="${1:-$PROJECT_ROOT/dts}"
mkdir -p "$OUTPUT_DIR"

QEMU="${PROJECT_ROOT}/build/qemu/install/bin/qemu-system-riscv64"
DTB_FILE="${OUTPUT_DIR}/qemu-virt.dtb"
DTS_FILE="${OUTPUT_DIR}/qemu-virt.dts"

if [ ! -x "$QEMU" ]; then
    echo "Error: QEMU not found at $QEMU"
    exit 1
fi

echo "Dumping QEMU virt DTB with WorldGuard enabled..."

# Run QEMU to dump DTB (with WorldGuard enabled)
$QEMU \
    -M virt,wg=on,wg-nworlds=4,wg-trustedwid=3,dumpdtb="$DTB_FILE" \
    -m 2G \
    -smp 1 \
    -nographic

if [ ! -f "$DTB_FILE" ]; then
    echo "Error: DTB file not created"
    exit 1
fi

echo "Converting DTB to DTS..."
dtc -I dtb -O dts -o "$DTS_FILE" "$DTB_FILE" 2>/dev/null

echo "DTB dump complete:"
echo "  DTB: $DTB_FILE"
echo "  DTS: $DTS_FILE"

# Show WorldGuard-related nodes if any
echo ""
echo "WorldGuard nodes in DTS:"
grep -n -A5 "worldguard\|wgchecker" "$DTS_FILE" 2>/dev/null || echo "  (no WorldGuard nodes found - need to add manually)"
