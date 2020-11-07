#!/bin/bash
#
# Patch Buildroot with the given RPi bluetooth firmware version and commit
#

set -e

SCRIPT_DIR="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

if [ -z "$1" ]; then
    echo "Need a commit ID!"
    exit 1
fi

FIRMWARE_URL="https://github.com/RPi-Distro/bluez-firmware/archive/$1.tar.gz"
FIRMWARE_FILE="rpi-bt-firmware-$1.tar.gz"
echo "Using firmware: $FIRMWARE_URL"

if [ -z "$2" ]; then
    PATCH_FILE="$SCRIPT_DIR/../buildroot-patches/003-rpi-bt-firmware-bump.patch"
    echo "Using default patch file: $PATCH_FILE"
else
    PATCH_FILE="$2"
fi

if [ ! -f "$PATCH_FILE" ]; then
    echo "Buildroot patch file not found: $PATCH_FILE"
    exit 1
fi

patch -Rf -d $SCRIPT_DIR/../buildroot -p 1 < "$PATCH_FILE"

rm -rf /tmp/$FIRMWARE_FILE
curl -Lo /tmp/$FIRMWARE_FILE "$FIRMWARE_URL"
checksum="$(sha256sum /tmp/$FIRMWARE_FILE | cut -d' ' -f 1)"
rm -rf /tmp/$FIRMWARE_FILE


sed -i "s/+RPI_BT_FIRMWARE_VERSION = [a-f0-9]*/+RPI_BT_FIRMWARE_VERSION = $1/g" "$PATCH_FILE"
sed -i "s/+sha256 [a-f0-9]*  rpi-bt-firmware-[a-f0-9]*.tar.gz/+sha256 $checksum  $FIRMWARE_FILE/g" "$PATCH_FILE"

patch -d $SCRIPT_DIR/../buildroot -p 1 < "$PATCH_FILE"
git commit -sm "feat: Update RPi BT firmware $1" "$PATCH_FILE" $SCRIPT_DIR/../buildroot/package/rpi-bt-firmware
