#!/bin/bash
#
# Buildroot post-build script: configured in BR2_ROOTFS_POST_BUILD_SCRIPT.
# Parameters:
# $1: target output directory (Buildroot default, also set in $TARGET_DIR)
# $2: board directory (configured in BR2_ROOTFS_POST_SCRIPT_ARGS)
# $3: board hook file (configured in BR2_ROOTFS_POST_SCRIPT_ARGS)

set -u
set -e

SCRIPT_DIR="$(dirname $0)"
BOARD_DIR="$2"
HOOK_FILE="$3"

. "${BOARD_DIR}/meta.sh"

. "${HOOK_FILE}"


# Determine build version
BUILD_VERSION=$("$SCRIPT_DIR/git-version.sh" "$BR2_EXTERNAL/version")

echo "Setting build version in YIO env variable: $BUILD_VERSION"
sed -i "s/\$BUILD_VERSION/$BUILD_VERSION/g" $1/etc/profile.d/yio.sh

# We need the Git hash of remote-os and not of the buildroot submodule!
GIT_HASH=`cd $SCRIPT_DIR; git rev-parse HEAD`

echo "Setting Git hash in YIO env variable: $GIT_HASH"
sed -i "s/\$GIT_HASH/$GIT_HASH/g" $1/etc/profile.d/yio.sh

QT_VERSION=`$HOST_DIR/bin/qmake -query QT_VERSION`
echo "Setting Qt version in env variable: $QT_VERSION"
sed -i "s/\$QT_VERSION/$QT_VERSION/g" $1/etc/profile.d/qt.sh

# Very simple SWUpdate hardware revision identification. See: https://sbabic.github.io/swupdate/sw-description.html#hardware-compatibility
echo "yio $BOARD_ID" > $1/etc/hwrevision

yios_post_build
