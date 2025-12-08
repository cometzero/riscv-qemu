#!/bin/bash
# Run QEMU with RISC-V virt machine and full boot chain
# Boot flow: OpenSBI → Linux Kernel → Buildroot rootfs
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/env.sh"

# QEMU binary location
QEMU_BIN="${QEMU_SRC}/build/qemu-system-riscv64"

# Boot images
OPENSBI="${OPENSBI_BUILD}/platform/generic/firmware/fw_jump.bin"
KERNEL="${LINUX_BUILD}/arch/riscv/boot/Image"
INITRD="${ROOTFS_BUILD}/images/rootfs.cpio.gz"

# Configuration
MACHINE="virt"
MEMORY="256M"
SMP="1"

echo "=== RISC-V QEMU Boot ==="
echo "QEMU:    ${QEMU_BIN}"
echo "OpenSBI: ${OPENSBI}"
echo "Kernel:  ${KERNEL}"
echo "Initrd:  ${INITRD}"
echo ""

# Check files exist
missing=""
[ ! -f "${QEMU_BIN}" ] && missing="${missing} QEMU"
[ ! -f "${OPENSBI}" ] && missing="${missing} OpenSBI"
[ ! -f "${KERNEL}" ] && missing="${missing} Kernel"
[ ! -f "${INITRD}" ] && missing="${missing} Initrd"

if [ -n "${missing}" ]; then
    echo "ERROR: Missing components:${missing}"
    echo "Run ./scripts/build_all.sh first."
    exit 1
fi

echo "Starting QEMU..."
echo "Exit: Ctrl+A then X"
echo ""

exec "${QEMU_BIN}" \
    -M ${MACHINE} \
    -m ${MEMORY} \
    -smp ${SMP} \
    -nographic \
    -bios "${OPENSBI}" \
    -kernel "${KERNEL}" \
    -initrd "${INITRD}" \
    -append "console=ttyS0 earlycon=sbi"
