#!/bin/bash
#
# Download, patch and commit a new Buildroot version.
#

set -e

SCRIPT_DIR="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

if [ -z "$1" ]; then
    echo "Need a buildroot version!"
    exit 1
fi

rm -rf /tmp/buildroot-new
mkdir -p /tmp/buildroot-new

echo "Downloading Buildroot $1..."
curl -L "https://buildroot.org/downloads/buildroot-${1}.tar.bz2" \
    | tar xvpjf - --strip 1 -C /tmp/buildroot-new 

if [ -n "$(ls -A $SCRIPT_DIR/../buildroot-patches 2>/dev/null)" ]
then
    echo "Applying patches..."
    for patch_file in $SCRIPT_DIR/../buildroot-patches/*.patch; do
        echo "Patch: ${patch_file}"
        patch -d /tmp/buildroot-new -p 1 < "${patch_file}";
    done
else
  echo "No local patches found"
fi

echo "Replacing Buildroot version in project..."
rm -rf $SCRIPT_DIR/../buildroot
mv /tmp/buildroot-new $SCRIPT_DIR/../buildroot

git add $SCRIPT_DIR/../buildroot
git commit -sam "feat: Update Buildroot to ${1}"
