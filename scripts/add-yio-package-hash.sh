#!/bin/bash
#------------------------------------------------------------------------------
# Helper script to add a version hash to a custom YIO Buildroot package.
#
# Copyright (C) 2020 Markus Zehnder <business@markuszehnder.ch>
#
# This file is part of the YIO-Remote software project.
#
# YIO-Remote software is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# YIO-Remote software is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with YIO-Remote software. If not, see <https://www.gnu.org/licenses/>.
#
# SPDX-License-Identifier: GPL-3.0-or-later
#------------------------------------------------------------------------------

set -e

SCRIPT_DIR="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

. $SCRIPT_DIR/lib/common.sh

#=============================================================

usage() {
  cat << EOF

Usage:
$0 REPO [VERSION]
  Add the version hash information of the given YIO repository to the custom
  Buildroot YIO package in package/yio-remote/<component>.
  If no version is specified, the latest release is retrieved from GitHub.

$0 -a
  Add the latest release version hash to ALL custom Buildroot YIO packages.

EOF
  exit 1
}

#=============================================================

# Download LICENSE file from given YIO repo and version
# Parameters:
# $1: YIO GitHub repository name. E.g. "integration.dock"
# $2: Version number. E.g. "v0.1.2"
# $3: Archive file name
# $4: Hash file name
createHashFileFromLicenseOnly() {
    curl -L --fail -s -H "Accept:application/vnd.github.v3.raw" -o LICENSE "https://api.github.com/repos/YIO-Remote/$1/contents/LICENSE?ref=$2"

    echo "none  xxx  $3" > $4
    echo -n "sha256  " >> $4
    shasum -a 256 LICENSE >> $4

    rm LICENSE
}

# For documentation purposes only.
# Unfortunately Buildroot does its own tarball from a local repo clone which I wasn't able to reproduce.
# Closest match which produces the same tarball content but with a different hash:
# GIT=git BR_BACKEND_DL_GETOPTS=":hc:d:o:n:N:H:ru:qf:e" ../buildroot/support/download/git -c v0.6.3 -d ./t1 -n yio-integration-dock-v0.6.3 -N yio-integration-dock -f yio-integration-dock-v0.6.3.tar.gz -u git://github.com/YIO-Remote/integration.dock.git -o ./t2 --
# Parameters:
# $1: YIO GitHub repository name. E.g. "integration.dock"
# $2: Version number. E.g. "v0.1.2"
# $3: Archive file name
# $4: Hash file name
createHashFileFromGitTarball() {
    curl -L --fail -o $3 https://github.com/YIO-Remote/$1/tarball/$2

    tar xzf $3 --strip-components=1 $REPO-${2/v/}/LICENSE

    echo -n "sha256  " > $4
    shasum -a 256 $3 >> $4
    echo -n "sha256  " >> $4
    shasum -a 256 LICENSE >> $4

    rm LICENSE
    rm $3
}

#=============================================================
getPackageNameFromRepo() {
    for item in ${YioRepos[*]}; do
        local repo=$(awk -F, '{print $1}' <<< $item)
        local name=$(awk -F, '{print $2}' <<< $item)
        if [[ $repo == $1 ]]; then
            PACKAGE_NAME=$name
            return
        fi
    done
    echo "Unknown repository: $1"
    exit 1
}

# Parameters:
# $1: YIO GitHub repository name. E.g. "integration.dock"
# $2: Optional version number. E.g. "v0.1.2"
createReleaseHash() {
    REPO=$1

    getPackageNameFromRepo $REPO

    echo "Buildroot package: $PACKAGE_NAME"

    if [ "$#" -gt 1 ]; then
        PACKAGE_VERSION=$2
    else
        getLatestRelease $REPO
        echo "  Latest release on GitHub: $LATEST_RELEASE"
        PACKAGE_VERSION=$LATEST_RELEASE
    fi

    local PACKAGE_DIR=$SCRIPT_DIR/../buildroot-external/package/yio-remote/$PACKAGE_NAME/$PACKAGE_VERSION
    local ARCHIVE_FILE=$PACKAGE_NAME-$PACKAGE_VERSION.tar.gz
    local HASH_FILE=$PACKAGE_NAME.hash

    if [[ -f $PACKAGE_DIR/$HASH_FILE ]]; then
        echo "  Custom buildroot package version already exists"
    else
        mkdir -p $PACKAGE_DIR
        cd $PACKAGE_DIR

        createHashFileFromLicenseOnly $REPO $PACKAGE_VERSION $ARCHIVE_FILE $HASH_FILE
        echo "  Created hash file: $PACKAGE_DIR/$HASH_FILE"
    fi
}

createLatestReleaseHashes() {
    for item in ${YioRepos[*]}; do
        local REPO=$(awk -F, '{print $1}' <<< $item)

        createReleaseHash $REPO
    done

    exit 0
}

#------------------------------------------------------------------------------
# Start of script
#------------------------------------------------------------------------------
# check command line arguments
while getopts "ah" opt; do
  case ${opt} in
    a ) if [ "$#" -ne 1 ]; then usage; fi
        createLatestReleaseHashes
        ;;
    h )
        usage
        ;;
    : )
        echo "Option: -$OPTARG requires an argument" 1>&2
        usage
        ;;
   \? )
        echo "Invalid option: -$OPTARG" 1>&2
        usage
        ;;
  esac
done

if [ "$#" -eq 0 ]; then
    usage
fi

createReleaseHash $1 $2
