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
echo "$BUILD_VERSION" > ${TARGET_DIR}/etc/VERSION.txt

# We need the Git hash of remote-os and not of the buildroot submodule!
GIT_HASH=`cd $SCRIPT_DIR; git rev-parse HEAD`

echo "Setting Git hash in YIO env variable: $GIT_HASH"
sed -i "s/\$GIT_HASH/$GIT_HASH/g" $1/etc/profile.d/yio.sh

QT_VERSION=`$HOST_DIR/bin/qmake -query QT_VERSION`
echo "Setting Qt version in env variable: $QT_VERSION"
sed -i "s/\$QT_VERSION/$QT_VERSION/g" $1/etc/profile.d/qt.sh

# Relocate dropbear's key storage from /etc/dropbear to /var/lib/dropbear
# See also: ../overlay/etc/systemd/system/dropbear.service.d/create-host-key-directory.conf
rm -f ${TARGET_DIR}/etc/dropbear
ln -s /var/lib/dropbear ${TARGET_DIR}/etc/dropbear

# Add mount points
mkdir -p "${TARGET_DIR}/boot"
mkdir -p "${TARGET_DIR}/etc/wpa_supplicant"

# additional directories
# - due to log error: bluetoothd[135]: Unable to open adapter storage directory: /var/lib/bluetooth/<MAC:ADDR>
mkdir -p "${TARGET_DIR}/var/lib/bluetooth"
