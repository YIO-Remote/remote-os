#!/bin/sh

# abort if a command fails
set -e

BOARD_DIR="$(dirname $0)"
BOARD_NAME="$(basename ${BOARD_DIR})"
GENIMAGE_CFG="${BOARD_DIR}/genimage.cfg"
GENIMAGE_TMP="${BUILD_DIR}/genimage.tmp"

cp ${BOARD_DIR}/boot/*.txt ${BINARIES_DIR}/
cp ${BOARD_DIR}/boot/*.json ${BINARIES_DIR}/

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
