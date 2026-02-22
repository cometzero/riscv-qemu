#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/env.sh"

QEMU_BIN="${QEMU_SRC}/build/qemu-system-riscv64"
SPL_BIN="${UBOOT_BUILD}/spl/u-boot-spl.bin"
FIT_BIN="${UBOOT_BUILD}/u-boot.itb"
KERNEL="${LINUX_BUILD}/arch/riscv/boot/Image"
INITRD="${ROOTFS_BUILD}/images/rootfs.cpio.gz"
BOOT_IMG="${BUILD_DIR}/boot.img"
DTB_SRC="${RISCV_QEMU_ROOT}/configs/dts/qemu-virt-worldguard.dts"
DTB_FILE="${BUILD_DIR}/dts/qemu_rv64_craft.dtb"

if [ ! -f "${DTB_SRC}" ] && [ -f "${RISCV_QEMU_ROOT}/dts/qemu-virt-worldguard.dts" ]; then
    DTB_SRC="${RISCV_QEMU_ROOT}/dts/qemu-virt-worldguard.dts"
fi

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
[ ! -f "${FIT_BIN}" ] && missing="${missing} FIT"
[ ! -f "${KERNEL}" ] && missing="${missing} Kernel"
[ ! -f "${INITRD}" ] && missing="${missing} Initrd"
[ ! -f "${DTB_FILE}" ] && missing="${missing} DTB"

if [ -n "${missing}" ]; then
    echo "ERROR: Missing components:${missing}"
    echo "Run ./scripts/build_all.sh first."
    exit 1
fi

echo "=== RISC-V QEMU Boot (WorldGuard) ==="
echo "QEMU:   ${QEMU_BIN}"
echo "SPL:    ${SPL_BIN}"
echo "FIT:    ${FIT_BIN}"
echo "Kernel: ${KERNEL}"
echo "Initrd: ${INITRD}"
echo "DTB:    ${DTB_FILE}"
echo ""

echo "Creating boot image..."
BOOT_IMG_SIZE=64
dd if=/dev/zero of="${BOOT_IMG}" bs=1M count=${BOOT_IMG_SIZE} conv=notrunc 2>/dev/null
mkfs.vfat -F 32 "${BOOT_IMG}" >/dev/null

cat << BOOTSCR > "${BUILD_DIR}/boot.cmd"
load virtio 0:0 ${KERNEL_LOAD_ADDR:-0x84000000} Image
load virtio 0:0 ${INITRD_LOAD_ADDR:-0x88000000} initrd.img
setenv bootargs console=ttyS0 earlycon=sbi wgtest=on
booti ${KERNEL_LOAD_ADDR:-0x84000000} ${INITRD_LOAD_ADDR:-0x88000000}:\${filesize} \${fdtcontroladdr}

BOOTSCR

if command -v mkimage >/dev/null 2>&1; then
    mkimage -A riscv -T script -C none -d "${BUILD_DIR}/boot.cmd" "${BUILD_DIR}/boot.scr"
else
    cp "${BUILD_DIR}/boot.cmd" "${BUILD_DIR}/boot.scr"
fi

mcopy -i "${BOOT_IMG}" "${KERNEL}" ::Image
mcopy -i "${BOOT_IMG}" "${INITRD}" ::initrd.img
mcopy -i "${BOOT_IMG}" "${BUILD_DIR}/boot.scr" ::boot.scr

exec "${QEMU_BIN}" \
    -M virt,wg=on \
    -m ${QEMU_MEMORY:-4G} \
    -smp ${QEMU_SMP:-2} \
    -nographic \
    -bios "${SPL_BIN}" \
    -device loader,file="${FIT_BIN}",addr=${QEMU_FIT_ADDR:-0x80200000} \
    -drive file="${BOOT_IMG}",format=raw,if=none,id=hd0 \
    -device virtio-blk-device,drive=hd0 \
    -netdev user,id=net0 \
    -device virtio-net-device,netdev=net0 \
    -dtb "${DTB_FILE}"
