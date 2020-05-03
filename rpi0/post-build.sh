#!/bin/sh

set -u
set -e

SCRIPT_DIR=$(dirname $0)

# Add a console on tty1
if [ -e ${TARGET_DIR}/etc/inittab ]; then
    grep -qE '^tty1::' ${TARGET_DIR}/etc/inittab || \
	sed -i '/GENERIC_SERIAL/a\
tty1::respawn:/sbin/getty -L  tty1 0 vt100 # HDMI console' ${TARGET_DIR}/etc/inittab
fi

ln -fs ../../../../usr/lib/systemd/system/wpa_supplicant@.service $1/etc/systemd/system/multi-user.target.wants/wpa_supplicant@wlan0.service

ln -fs ../../../../usr/lib/systemd/system/backlight.service $1/etc/systemd/system/multi-user.target.wants/backlight.service

ln -fs ../../../../usr/lib/systemd/system/sharp-init.service $1/etc/systemd/system/multi-user.target.wants/sharp-init.service

ln -fs ../../../../usr/lib/systemd/system/app.service $1/etc/systemd/system/multi-user.target.wants/app.service


rm -rf $1/var/log/journal

#rm -r $1/etc/systemd/system/sysinit.target.wants/systemd-timesyncd.service

#rm -r $1/etc/systemd/system/multi-user.target.wants/dhcpcd.service

# Determine build version
BUILD_VERSION=$("$SCRIPT_DIR/git-version.sh" "$BR2_EXTERNAL/version")

# We need the Git hash of remote-os and not of the buildroot submodule!
GIT_HASH=`cd $1; git rev-parse HEAD`

echo "Setting build version in YIO env variable: $BUILD_VERSION"
sed -i "s/\$BUILD_VERSION/$BUILD_VERSION/g" $1/etc/profile.d/yio.sh

echo "Setting Git hash in YIO env variable: $GIT_HASH"
sed -i "s/\$GIT_HASH/$GIT_HASH/g" $1/etc/profile.d/yio.sh
