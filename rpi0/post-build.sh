#!/bin/sh

set -u
set -e

SCRIPT_DIR="$(dirname $0)"

# Add a console on tty1
if [ -e ${TARGET_DIR}/etc/inittab ]; then
    grep -qE '^tty1::' ${TARGET_DIR}/etc/inittab || \
	sed -i '/GENERIC_SERIAL/a\
tty1::respawn:/sbin/getty -L  tty1 0 vt100 # HDMI console' ${TARGET_DIR}/etc/inittab
fi

# Determine build version
BUILD_VERSION=$("$SCRIPT_DIR/git-version.sh" "$BR2_EXTERNAL/version")

echo "Setting build version in YIO env variable: $BUILD_VERSION"
sed -i "s/\$BUILD_VERSION/$BUILD_VERSION/g" $1/etc/profile.d/yio.sh

# We need the Git hash of remote-os and not of the buildroot submodule!
GIT_HASH=`cd $SCRIPT_DIR; git rev-parse HEAD`

echo "Setting Git hash in YIO env variable: $GIT_HASH"
sed -i "s/\$GIT_HASH/$GIT_HASH/g" $1/etc/profile.d/yio.sh
