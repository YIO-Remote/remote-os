#!/bin/bash
#
# Buildroot post-image script: configured in BR2_ROOTFS_POST_IMAGE_SCRIPT.
# Parameters:
# $1: target output directory (Buildroot default)
# $2: board directory (configured in BR2_ROOTFS_POST_SCRIPT_ARGS)
# $3: board hook file (configured in BR2_ROOTFS_POST_SCRIPT_ARGS)

# abort if a command fails
set -e

SCRIPT_DIR="$(dirname $0)"
BOARD_DIR="$2"
HOOK_FILE="$3"

. "${BOARD_DIR}/meta.sh"

. "${SCRIPT_DIR}/disk-image.sh"
. "${SCRIPT_DIR}/swupdate-image.sh"
. "${HOOK_FILE}"


touch ${BR2_EXTERNAL_YIOS_PATH}/.toolchain-ready

BUILD_VERSION=$("$SCRIPT_DIR/git-version.sh" "$BR2_EXTERNAL/version")
BUILD_DATE=$(date --iso-8601=seconds)

# patch README file with build version and build timestamp
if [[ -f ${BINARIES_DIR}/README.md ]]; then
    echo "Setting build version in README.md: $BUILD_VERSION"
    sed -i "s/\$BUILD_VERSION/$BUILD_VERSION/g" ${BINARIES_DIR}/README.md
    sed -i "s/\$BUILD_DATE/$BUILD_DATE/g" ${BINARIES_DIR}/README.md
    # for our Windows users:
    unix2dos ${BINARIES_DIR}/README.md
fi

echo "Generating file systems and SD card image ..."

yios_pre_image

create_disk_image
#create_ota_update

yios_post_image
