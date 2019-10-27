#!/bin/sh

BOARD_DIR="$(dirname $0)"
BOARD_NAME="$(basename ${BOARD_DIR})"
GENIMAGE_CFG="${BOARD_DIR}/genimage-${BOARD_NAME}.cfg"
GENIMAGE_TMP="${BUILD_DIR}/genimage.tmp"

cp ../board/yio-remote/${BOARD_NAME}/config.txt ${BINARIES_DIR}/
cp ../board/yio-remote/${BOARD_NAME}/cmdline.txt ${BINARIES_DIR}/
cp ../board/yio-remote/${BOARD_NAME}/config.json ${BINARIES_DIR}/

cp -r ../board/yio-remote/${BOARD_NAME}/cfg_templates ${BINARIES_DIR}
cp -r ../board/yio-remote/${BOARD_NAME}/overlays ${BINARIES_DIR}

mv ${BINARIES_DIR}/zImage ${BINARIES_DIR}/kernel.img

rm -rf "${GENIMAGE_TMP}"

genimage                           \
	--rootpath "${TARGET_DIR}"     \
	--tmppath "${GENIMAGE_TMP}"    \
	--inputpath "${BINARIES_DIR}"  \
	--outputpath "${BINARIES_DIR}" \
	--config "${GENIMAGE_CFG}"

exit $?
