#!/bin/bash
# Run QEMU with RISC-V virt machine and full boot chain
# Boot flow: U-Boot SPL → OpenSBI → U-Boot proper → Linux Kernel → Buildroot
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/env.sh"

# Parse arguments
DEBUG_ARGS=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --debug)
            DEBUG_ARGS="-S -s"
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [--debug]"
            echo "  --debug  Enable QEMU GDB stub (-S -s)"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# QEMU binary location
QEMU_BIN="${QEMU_SRC}/build/qemu-system-riscv64"

# Boot images - U-Boot SPL boot path
SPL_BIN="${UBOOT_BUILD}/spl/u-boot-spl.bin"
FIT_BIN="${UBOOT_BUILD}/u-boot.itb"

# Kernel and rootfs
KERNEL="${LINUX_BUILD}/arch/riscv/boot/Image"
INITRD="${ROOTFS_BUILD}/images/rootfs.cpio.gz"

# Boot disk image
BOOT_IMG="${BUILD_DIR}/boot.img"

# Configuration
MACHINE="virt"
MEMORY="4G"
SMP="2"
FIT_ADDR="0x80200000"

echo "=== RISC-V QEMU Boot ==="
echo "Boot Flow: U-Boot SPL → OpenSBI → U-Boot proper → Linux → Buildroot"
echo ""
echo "QEMU:   ${QEMU_BIN}"
echo "SPL:    ${SPL_BIN}"
echo "FIT:    ${FIT_BIN}"
echo "Kernel: ${KERNEL}"
echo "Initrd: ${INITRD}"
echo ""

# Check files exist
missing=""
[ ! -f "${QEMU_BIN}" ] && missing="${missing} QEMU"
[ ! -f "${SPL_BIN}" ] && missing="${missing} SPL"
[ ! -f "${FIT_BIN}" ] && missing="${missing} FIT"
[ ! -f "${KERNEL}" ] && missing="${missing} Kernel"
[ ! -f "${INITRD}" ] && missing="${missing} Initrd"

if [ -n "${missing}" ]; then
    echo "ERROR: Missing components:${missing}"
    echo "Run ./scripts/build_all.sh first."
    exit 1
fi

# Create boot FAT image with kernel and initramfs
echo "Creating boot image..."
BOOT_IMG_SIZE=64  # MB
dd if=/dev/zero of="${BOOT_IMG}" bs=1M count=${BOOT_IMG_SIZE} 2>/dev/null
mkfs.vfat -F 32 "${BOOT_IMG}" >/dev/null

# Prepare boot files locally
cat << 'BOOTSCR' > "${BUILD_DIR}/boot.cmd"
echo "Loading kernel from virtio disk..."
load virtio 0:0 0x84000000 Image
load virtio 0:0 0x88000000 initrd.img
setenv bootargs console=ttyS0 earlycon=sbi
booti 0x84000000 0x88000000:${filesize} ${fdtcontroladdr}
BOOTSCR

# Create compiled boot script or use text version if mkimage missing
if command -v mkimage >/dev/null 2>&1; then
    mkimage -A riscv -T script -C none -d "${BUILD_DIR}/boot.cmd" "${BUILD_DIR}/boot.scr"
else
    echo "WARNING: mkimage not found, using text boot script"
    cp "${BUILD_DIR}/boot.cmd" "${BUILD_DIR}/boot.scr"
fi

# Copy files to proper locations in FAT image using mcopy (no sudo needed)
# -i specifies the image file, :: specifies path inside the FAT image
mcopy -i "${BOOT_IMG}" "${KERNEL}" ::Image
mcopy -i "${BOOT_IMG}" "${INITRD}" ::initrd.img
mcopy -i "${BOOT_IMG}" "${BUILD_DIR}/boot.scr" ::boot.scr

echo "Starting QEMU..."
echo "Exit: Ctrl+A then X"
echo ""

exec "${QEMU_BIN}" \
    -M ${MACHINE} \
    -m ${MEMORY} \
    -smp ${SMP} \
    -nographic \
    -bios "${SPL_BIN}" \
    -device loader,file="${FIT_BIN}",addr=${FIT_ADDR} \
    -drive file="${BOOT_IMG}",format=raw,if=none,id=hd0 \
    -device virtio-blk-device,drive=hd0 \
    -netdev user,id=net0 \
    -device virtio-net-device,netdev=net0 \
    ${DEBUG_ARGS}
