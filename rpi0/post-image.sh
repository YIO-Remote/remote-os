#!/bin/sh

# abort if a command fails
set -e

SCRIPT_DIR="$(dirname $0)"
BOARD_DIR="$(dirname $0)"
BOARD_NAME="$(basename ${BOARD_DIR})"
GENIMAGE_CFG="${BOARD_DIR}/genimage.cfg"
GENIMAGE_TMP="${BUILD_DIR}/genimage.tmp"

touch ${BR2_EXTERNAL_BUILDROOT_SUBMODULE_PATH}/.toolchain-ready

if [ "$SKIP_BUILD_IMAGE" = "y" ]; then
    echo "WARN: not building SD card image: disabled with SKIP_BUILD_IMAGE"
    exit
fi

# gather files for boot partition
cp ${BOARD_DIR}/boot/*.txt ${BINARIES_DIR}/
cp ${TARGET_DIR}/opt/yio/app/config.json.def ${BINARIES_DIR}/config.json
cp ${BOARD_DIR}/boot/*.md ${BINARIES_DIR}/
cp ${BOARD_DIR}/boot/*.template ${BINARIES_DIR}/

mkdir -p ${BINARIES_DIR}/overlays
cp ${BOARD_DIR}/boot/overlays/*.dtbo ${BINARIES_DIR}/overlays/

cp ${BINARIES_DIR}/zImage ${BINARIES_DIR}/kernel.img

echo "Generating file systems and SD card image ..."

# patch README file with build version and build timestamp
BUILD_VERSION=$("$SCRIPT_DIR/git-version.sh" "$BR2_EXTERNAL/version")
BUILD_DATE=$(date --iso-8601=seconds)

echo "Setting build version in README.md: $BUILD_VERSION"
sed -i "s/\$BUILD_VERSION/$BUILD_VERSION/g" ${BINARIES_DIR}/README.md
sed -i "s/\$BUILD_DATE/$BUILD_DATE/g" ${BINARIES_DIR}/README.md
# for our Windows users:
unix2dos ${BINARIES_DIR}/README.md

# create SD card image
rm -rf "${GENIMAGE_TMP}"

rm -rf ${BINARIES_DIR}/recovery.ext4
dd if=/dev/zero of=${BINARIES_DIR}/recovery.ext4 bs=1M count=752
mke2fs -t ext4 -L 'YIO recovery' ${BINARIES_DIR}/recovery.ext4

rm -rf ${BINARIES_DIR}/varfs.ext4
dd if=/dev/zero of=${BINARIES_DIR}/varfs.ext4 bs=1M count=356
mke2fs -t ext4 -L 'YIO var' ${BINARIES_DIR}/varfs.ext4

rm -rf ${BINARIES_DIR}/userdata.ext4
dd if=/dev/zero of=${BINARIES_DIR}/userdata.ext4 bs=1M count=280
mke2fs -t ext4 -L 'YIO data' ${BINARIES_DIR}/userdata.ext4

genimage                           \
	--rootpath "${TARGET_DIR}"     \
	--tmppath "${GENIMAGE_TMP}"    \
	--inputpath "${BINARIES_DIR}"  \
	--outputpath "${BINARIES_DIR}" \
	--config "${GENIMAGE_CFG}"

echo "Generating hash for rootfs.ext4 ..."
shasum -a 256 ${BINARIES_DIR}/rootfs.ext4 | grep -oh "^.\+ " > ${BINARIES_DIR}/rootfs.ext4.hash

echo "Generating hash for boot.vfat ..."
shasum -a 256 ${BINARIES_DIR}/boot.vfat | grep -oh "^.\+ " > ${BINARIES_DIR}/boot.vfat.hash

echo "Generating hash for yio-remote-sdcard.img ..."
shasum -a 256 ${BINARIES_DIR}/yio-remote-sdcard.img | grep -oh "^.\+ " > ${BINARIES_DIR}/yio-remote-sdcard.img.hash

echo "Zipping SD card image ..."
rm -f ${BINARIES_DIR}/yio-remote-sdcard.zip
# TODO include release notes
zip -j ${BINARIES_DIR}/yio-remote-sdcard.zip ${BINARIES_DIR}/yio-remote-sdcard.img ${BINARIES_DIR}/yio-remote-sdcard.img.hash ${BINARIES_DIR}/README.md

echo "Cleaning up partition image files ..."
rm ${BINARIES_DIR}/kernel.img

exit $?
