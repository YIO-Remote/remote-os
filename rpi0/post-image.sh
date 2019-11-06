#!/bin/sh

# abort if a command fails
set -e

BOARD_DIR="$(dirname $0)"
BOARD_NAME="$(basename ${BOARD_DIR})"
GENIMAGE_CFG="${BOARD_DIR}/genimage.cfg"
GENIMAGE_TMP="${BUILD_DIR}/genimage.tmp"

touch ${BR2_EXTERNAL_BUILDROOT_SUBMODULE_PATH}/.toolchain-ready

if [ "$SKIP_BUILD_IMAGE" = "y" ]; then
    echo "WARN: not building SD card image: disabled with SKIP_BUILD_IMAGE"
    exit
fi

cp ${BOARD_DIR}/boot/*.txt ${BINARIES_DIR}/
cp ${TARGET_DIR}/usr/bin/yio-remote/config.json.def ${BINARIES_DIR}/config.json

mkdir -p ${BINARIES_DIR}/overlays
cp ${BOARD_DIR}/boot/overlays/*.dtbo ${BINARIES_DIR}/overlays/

cp ${BINARIES_DIR}/zImage ${BINARIES_DIR}/kernel.img

rm -rf "${GENIMAGE_TMP}"

genimage                           \
	--rootpath "${TARGET_DIR}"     \
	--tmppath "${GENIMAGE_TMP}"    \
	--inputpath "${BINARIES_DIR}"  \
	--outputpath "${BINARIES_DIR}" \
	--config "${GENIMAGE_CFG}"

rm ${BINARIES_DIR}/kernel.img

exit $?
