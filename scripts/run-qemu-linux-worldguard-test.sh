#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/env.sh"

QEMU_BIN="${QEMU_SRC}/build/qemu-system-riscv64"
OPENSBI_BIN="${OPENSBI_BUILD}/platform/generic/firmware/fw_jump.bin"
KERNEL="${LINUX_BUILD}/arch/riscv/boot/Image"
INITRD="${ROOTFS_BUILD}/images/rootfs.cpio.gz"
DTB_SRC="${RISCV_QEMU_ROOT}/configs/dts/qemu-virt-worldguard.dts"
DTB_FILE="${BUILD_DIR}/dts/qemu_rv64_craft_worldguard_test.dtb"

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
[ ! -f "${OPENSBI_BIN}" ] && missing="${missing} OpenSBI"
[ ! -f "${KERNEL}" ] && missing="${missing} Kernel"
[ ! -f "${INITRD}" ] && missing="${missing} Initrd"
[ ! -f "${DTB_FILE}" ] && missing="${missing} DTB"

if [ -n "${missing}" ]; then
    echo "ERROR: Missing components:${missing}"
    echo "Run ./scripts/build_all.sh first (or build missing parts)."
    exit 1
fi

echo "=== RISC-V QEMU Linux Boot (WorldGuard Test) ==="
echo "QEMU:    ${QEMU_BIN}"
echo "OpenSBI: ${OPENSBI_BIN}"
echo "Kernel:  ${KERNEL}"
echo "Initrd:  ${INITRD}"
echo "DTB:     ${DTB_FILE}"
echo ""

exec "${QEMU_BIN}" \
    -M virt,wg=on \
    -m ${QEMU_MEMORY:-1G} \
    -smp ${QEMU_SMP:-1} \
    -nographic \
    -bios "${OPENSBI_BIN}" \
    -kernel "${KERNEL}" \
    -initrd "${INITRD}" \
    -append "console=ttyS0 earlycon=sbi keep_bootcon loglevel=8 rdinit=/init" \
    -dtb "${DTB_FILE}"
