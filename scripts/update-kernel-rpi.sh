#!/bin/bash
#
# Patch Buildroot with the given RPi kernel version and commit
#

set -e

SCRIPT_DIR="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

if [ -z "$1" ]; then
    echo "Need a commit ID!"
    exit 1
fi

if [ -z "$2" ]; then
    echo "Need a kernel version!"
    exit 1
fi

sed -i "s|BR2_LINUX_KERNEL_CUSTOM_TARBALL_LOCATION=\"https://github.com/raspberrypi/linux/.*\"|BR2_LINUX_KERNEL_CUSTOM_TARBALL_LOCATION=\"https://github.com/raspberrypi/linux/archive/$1.tar.gz\"|g" $SCRIPT_DIR/../buildroot-external/configs/*
git commit -sm "feat: Update RPi kernel $2 - $1" $SCRIPT_DIR/../buildroot-external/configs/*
