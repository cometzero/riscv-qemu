#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/env.sh"

TEST_DIR="${RISCV_QEMU_ROOT}/tests/worldguard"
QEMU_BIN="${QEMU_SRC}/build/qemu-system-riscv64"

if [ ! -x "${QEMU_BIN}" ]; then
    echo "ERROR: QEMU binary not found: ${QEMU_BIN}"
    echo "Run ./scripts/build_qemu.sh first."
    exit 1
fi

if [ ! -d "${TEST_DIR}" ]; then
    echo "ERROR: WorldGuard test directory missing: ${TEST_DIR}"
    exit 1
fi

echo "=== WorldGuard Baremetal Test ==="
echo "QEMU: ${QEMU_BIN}"
echo "Test: ${TEST_DIR}"
echo ""

make -C "${TEST_DIR}" clean
make -C "${TEST_DIR}" QEMU="${QEMU_BIN}" run
