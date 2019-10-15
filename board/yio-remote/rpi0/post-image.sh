#!/bin/sh

BOARD_DIR="$(dirname $0)"
BOARD_NAME="$(basename ${BOARD_DIR})"
GENIMAGE_CFG="${BOARD_DIR}/genimage-${BOARD_NAME}.cfg"
GENIMAGE_TMP="${BUILD_DIR}/genimage.tmp"

cp board/yio-remote/${BOARD_NAME}/config.txt ${BINARIES_DIR}/config.txt
cp board/yio-remote/${BOARD_NAME}/cmdline.txt ${BINARIES_DIR}/cmdline.txt
cp board/yio-remote/${BOARD_NAME}/config.json ${BINARIES_DIR}/config.json

mkdir -p ${BINARIES_DIR}/overlays
cp board/yio-remote/${BOARD_NAME}/goodix.dtbo ${BINARIES_DIR}/overlays/goodix.dtbo
cp board/yio-remote/${BOARD_NAME}/sharp.dtbo ${BINARIES_DIR}/overlays/sharp.dtbo
cp board/yio-remote/${BOARD_NAME}/pi3-miniuart-bt.dtbo ${BINARIES_DIR}/overlays/pi3-miniuart-bt.dtbo

mv ${BINARIES_DIR}/zImage ${BINARIES_DIR}/kernel.img

rm -rf "${GENIMAGE_TMP}"

genimage                           \
	--rootpath "${TARGET_DIR}"     \
	--tmppath "${GENIMAGE_TMP}"    \
	--inputpath "${BINARIES_DIR}"  \
	--outputpath "${BINARIES_DIR}" \
	--config "${GENIMAGE_CFG}"

exit $?
