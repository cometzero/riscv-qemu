#!/bin/bash

set -e

BOARD_DIR="$(dirname $0)"
GENIMAGE_CFG="${BOARD_DIR}/genimage.cfg"
GENIMAGE_TMP="${BUILD_DIR}/genimage.tmp"

# Create extlinux directory and config
mkdir -p "${BINARIES_DIR}/extlinux"
cat > "${BINARIES_DIR}/extlinux/extlinux.conf" <<EOF
label linux
  kernel /Image
  append root=/dev/vda2 rw console=ttyS0 earlycon=sbi
EOF

PROJECT_ROOT="$(realpath ${BR2_EXTERNAL_RISCV_BOOT_VERIFY_PATH}/../../..)"
LINUX_BUILD_DIR="${PROJECT_ROOT}/build/linux/arch/riscv/boot"

if [ -f "${LINUX_BUILD_DIR}/Image" ]; then
    cp "${LINUX_BUILD_DIR}/Image" "${BINARIES_DIR}/Image"
fi

rm -rf "${GENIMAGE_TMP}"

genimage                           \
	--rootpath "${TARGET_DIR}"     \
	--tmppath "${GENIMAGE_TMP}"    \
	--inputpath "${BINARIES_DIR}"  \
	--outputpath "${BINARIES_DIR}" \
	--config "${GENIMAGE_CFG}"

exit $?
