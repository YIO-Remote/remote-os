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

genimage                           \
	--rootpath "${TARGET_DIR}"     \
	--tmppath "${GENIMAGE_TMP}"    \
	--inputpath "${BINARIES_DIR}"  \
	--outputpath "${BINARIES_DIR}" \
	--config "${GENIMAGE_CFG}"

cd ${BINARIES_DIR}

SDCARD_IMG_NAME=yio-remote-sdcard-v${BUILD_VERSION}
mv yio-remote-sdcard.img ${SDCARD_IMG_NAME}.img

echo "Generating hash for rootfs.ext4 ..."
shasum -a 256 rootfs.ext4 > rootfs.ext4.sha256sum

echo "Generating hash for boot.vfat ..."
shasum -a 256 boot.vfat > boot.vfat.sha256sum

echo "Generating hash for ${SDCARD_IMG_NAME}.img ..."
shasum -a 256 ${SDCARD_IMG_NAME}.img > ${SDCARD_IMG_NAME}.img.sha256sum

echo "Zipping SD card image ..."
rm -f ${SDCARD_IMG_NAME}.zip
# TODO include release notes
zip -j ${SDCARD_IMG_NAME}.zip ${SDCARD_IMG_NAME}.img ${SDCARD_IMG_NAME}.img.sha256sum README.md

echo "Cleaning up partition image files ..."
rm kernel.img

exit $?
