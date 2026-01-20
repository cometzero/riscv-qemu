#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/env.sh"

QEMU_BIN="${QEMU_SRC}/build/qemu-system-riscv64"
SPL_BIN="${UBOOT_BUILD}/spl/u-boot-spl.bin"
KERNEL="${LINUX_BUILD}/arch/riscv/boot/Image"
DTB_SRC="${RISCV_QEMU_ROOT}/dts/qemu-virt-worldguard.dts"
DTB_FILE="${BUILD_DIR}/dts/qemu_rv64_craft.dtb"

if ! command -v dtc >/dev/null 2>&1; then
    echo "ERROR: dtc not found"
    exit 1
fi

mkdir -p "$(dirname "${DTB_FILE}")"
if [ ! -f "${DTB_FILE}" ] || [ "${DTB_SRC}" -nt "${DTB_FILE}" ]; then
    dtc -I dts -O dtb -o "${DTB_FILE}" "${DTB_SRC}"
fi

missing=""
[ ! -f "${QEMU_BIN}" ] && missing="${missing} QEMU"
[ ! -f "${SPL_BIN}" ] && missing="${missing} SPL"
[ ! -f "${KERNEL}" ] && missing="${missing} Kernel"
[ ! -f "${DTB_FILE}" ] && missing="${missing} DTB"

if [ -n "${missing}" ]; then
    echo "ERROR: Missing components:${missing}"
    echo "Run ./scripts/build_all.sh first."
    exit 1
fi

echo "=== RISC-V QEMU Boot (SPL, WorldGuard) ==="
echo "QEMU:   ${QEMU_BIN}"
echo "SPL:    ${SPL_BIN}"
echo "Kernel: ${KERNEL}"
echo "DTB:    ${DTB_FILE}"
echo ""

exec "${QEMU_BIN}" \
    -M virt,wg=on \
    -m ${QEMU_MEMORY:-4G} \
    -smp ${QEMU_SMP:-2} \
    -nographic \
    -bios "${SPL_BIN}" \
    -kernel "${KERNEL}" \
    -dtb "${DTB_FILE}"
