#!/bin/bash
# Run QEMU with RISC-V virt machine and full boot chain
# Boot flow: U-Boot SPL → OpenSBI → U-Boot proper → Linux Kernel → Buildroot
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/env.sh"

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
MEMORY="512M"
SMP="1"
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

# Mount and copy files
BOOT_MNT=$(mktemp -d)
sudo mount -o loop "${BOOT_IMG}" "${BOOT_MNT}"
sudo cp "${KERNEL}" "${BOOT_MNT}/Image"
sudo cp "${INITRD}" "${BOOT_MNT}/initrd.img"

# Create boot script for U-Boot
cat << 'BOOTSCR' | sudo tee "${BOOT_MNT}/boot.cmd" > /dev/null
echo "Loading kernel from virtio disk..."
load virtio 0:1 0x84000000 Image
load virtio 0:1 0x88000000 initrd.img
setenv bootargs console=ttyS0 earlycon=sbi
booti 0x84000000 0x88000000:${filesize} ${fdtcontroladdr}
BOOTSCR

# Create compiled boot script
mkimage -A riscv -T script -C none -d "${BOOT_MNT}/boot.cmd" "${BOOT_MNT}/boot.scr" 2>/dev/null || \
    sudo cp "${BOOT_MNT}/boot.cmd" "${BOOT_MNT}/boot.scr"

sudo umount "${BOOT_MNT}"
rmdir "${BOOT_MNT}"

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
    -device virtio-net-device,netdev=net0
