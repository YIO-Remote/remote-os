#!/bin/bash
#------------------------------------------------------------------------------
# YIO updater script
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

. /etc/profile.d/yio.sh
. $(dirname $0)/common
. $(dirname $0)/util.bash

WEB_CFG_REPO=web-configurator

#=============================================================

usage() {
  cat << EOF

Usage:
$0 COMPONENT FILE.(version|zip|tar)
  ! NOT YET IMPLEMENTED !
  Update a YIO component with the provided update marker file or archive.
  The archive may be a zip or tar archive. See wiki for update archive format.
  The archive and optional marker file are deleted after a success update!
  COMPONENT:
    app - remote-software application
    os  - remote-os (NOT YET IMPLEMENTED)
    web - web-configurator

$0 -r
  Check for latest release versions on GitHub and exit.
  Attention: this will count against the GitHub API rate limit on your IP address.
  Limit is 60 req/h (May 2020) and this option makes ~10 requests!
  https://developer.github.com/v3/#rate-limiting

$0 -u
  ! NOT YET IMPLEMENTED !
  Check for available updates and exit.

$0 [-v VERSION] -d DIRECTORY
  ! NOT YET IMPLEMENTED !
  Download a release from GitHub to given directory.
  The latest release version is downloaded if version option is not provided.

EOF
  exit 1
}

#=============================================================

PluginRepos=(
    "integration.dock,libdock.so"
    "integration.homey,libhomey.so"
    "integration.home-assistant,libhomeassistant.so"
    "integration.openhab,libopenhab.so"
    "integration.spotify,libspotify.so"
    "integration.openweather,libopenweather.so"
    "integration.roon,libroon.so"
)

#=============================================================

checkRelease() {
    getLatestRelease $1
    echo -e "$1 GitHub release:\t$LATEST_RELEASE"
    if [[ -z ${2}/version.txt && -f ${2}/version.txt ]]; then
        echo -e "$1 local version :\t$(< ${2}/version.txt)"
    fi
}

appendReleaseInfo() {
    local LOCAL_VERSION=?
    getLatestRelease $2
    if [[ ! -z $3 && -f ${3}/version.txt ]]; then
        LOCAL_VERSION=$(< ${3}/version.txt)
    elif [[ ! -z $4 && -f $4 ]]; then
        # TODO query plugin metadata. Probably need to write a little qt utility...
        LOCAL_VERSION=x
    fi
    echo "$2,$LATEST_RELEASE,$LOCAL_VERSION" >> $1
}

checkReleases() {
    echo "Retrieving version information from GitHub..."
    echo ""

    echo "Component,GitHub,Installed" > /tmp/versions.txt
    appendReleaseInfo /tmp/versions.txt remote-software $YIO_APP_DIR
    appendReleaseInfo /tmp/versions.txt $WEB_CFG_REPO $YIO_WEB_CONFIGURATOR_DIR
    echo "remote-os,$(getLatestRelease remote-os),$YIO_OS_VERSION" >> /tmp/versions.txt

    for item in ${PluginRepos[*]}; do
        local PROJECT=$(awk -F, '{print $1}' <<< $item)
        local LIBFILE=${YIO_PLUGIN_DIR}/$(awk -F, '{print $2}' <<< $item)

        appendReleaseInfo /tmp/versions.txt $PROJECT "" $LIBFILE
    done
    
    printTable ',' "$(cat /tmp/versions.txt)"
}

#------------------------------------------------------------------------------
# Start of script
#------------------------------------------------------------------------------
# check command line arguments
if [ "$#" -eq 0 ]; then
  usage
fi

while getopts "cd:v:frh" optname; do
  case "$optname" in
    "r")
      checkReleases
      exit 0
      ;;
    "d")
      DOWNLOAD=true
      DOWNLOAD_DIR="$OPTARG"
      echo "NOT YET IMPLEMENTED!"
      ;;
    "v")
      VERSION="$OPTARG"
      ;;
    "u")
      echo "NOT YET IMPLEMENTED!"
      exit 0
      ;;
    "h" | "?")
      usage
      ;;
    *)
      echo "Bug alert: error while processing options, check getopts definition"
      ;;
  esac
done

echo "NOT YET IMPLEMENTED!"
