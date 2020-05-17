#!/bin/bash
#------------------------------------------------------------------------------
# Main updater script for all YIO components.
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

DIR=$(dirname $0)
. /etc/profile.d/yio.sh
. $DIR/lib/common.bash
. $DIR/lib/util.bash

#=============================================================

usage() {
  cat << EOF

Usage:
$0 COMPONENT PARAMETERS
  Update a YIO component with the provided update marker file or archive.
  The archive may be a zip or tar archive. See wiki for update archive format.
  The archive and optional marker file are deleted after a success update!
  COMPONENT:
    app     remote-software application
    web     web-configurator
    os      remote-os (NOT YET IMPLEMENTED)
    plugin  integration plugin (NOT YET IMPLEMTED)

  PARAMETERS:
    FILE.(version|zip|tar)  update marker file or archive
    -h                      show help for specific component

$0 -r
  Check for latest release versions on GitHub and exit.
  Attention: this will count against the GitHub API rate limit on your IP address.
  Limit is 60 req/h (May 2020) and this option makes ~10 requests!
  https://developer.github.com/v3/#rate-limiting

$0 -u
  ! NOT YET IMPLEMENTED !
  Check for available updates using the YIO update server and exit.

$0 -d REPO [-v VERSION] [-o DIRECTORY]
  Download a release from GitHub to given output directory.
  The latest release version is downloaded if version option is not provided.
  If the output directory is not provided, /tmp is used.
  REPO   the YIO GitHub repository name:
         remote-software, web-configurator, integration.dock, ...

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

appendReleaseInfo() {
    local LOCAL_VERSION=-
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
    local VERSION_FILE=/tmp/versions.txt
    echo "Component,GitHub,Installed" > $VERSION_FILE
    appendReleaseInfo $VERSION_FILE remote-software $YIO_APP_DIR
    appendReleaseInfo $VERSION_FILE web-configurator $YIO_WEB_CONFIGURATOR_DIR
    getLatestRelease remote-os
    echo "remote-os,$LATEST_RELEASE,$YIO_OS_VERSION" >> $VERSION_FILE

    for item in ${PluginRepos[*]}; do
        local PROJECT=$(awk -F, '{print $1}' <<< $item)
        local LIBFILE=${YIO_PLUGIN_DIR}/$(awk -F, '{print $2}' <<< $item)

        appendReleaseInfo $VERSION_FILE $PROJECT "" $LIBFILE
    done
    
    echo ""
    printTable ',' "$(cat $VERSION_FILE)"
}

#=============================================================

doComponentDownload() {
    DOWNLOAD_DIR=/tmp
    # Process additional download options
    while getopts ":v:o:" opt; do
        case ${opt} in
            v )
            VERSION=$OPTARG
            ;;
            o )
            DOWNLOAD_DIR=$OPTARG
            ;;
            \? )
            echo "Invalid download option: -$OPTARG"
            usage
            ;;
            : )
            echo "Invalid download option: -$OPTARG requires an argument"
            usage
            ;;
        esac
    done

    if [[ ! -z $VERSION ]]; then
        downloadRelease $COMPONENT $VERSION $DOWNLOAD_DIR
    else
        downloadLatestRelease $COMPONENT $DOWNLOAD_DIR
    fi
}

#------------------------------------------------------------------------------
# Start of script
#------------------------------------------------------------------------------
# check command line arguments
if [ "$#" -eq 0 ]; then
    usage
fi

while getopts ":d:ruh" opt; do
  case ${opt} in
    r )
        checkReleases
        exit 0
        ;;
    u )
        echo "NOT YET IMPLEMENTED!"
        exit 1
        ;;
    d )
        COMPONENT="$OPTARG"
        shift $((OPTIND -1))
        OPTIND=1
        doComponentDownload $@
        exit 0
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

shift $((OPTIND -1))
OPTIND=1

COMPONENT=$1; shift 
case "$COMPONENT" in
  app)
    $DIR/app-update.sh $@ || exit $?
    exit 0
    ;;
  web)
    $DIR/web-configurator-update.sh $@ || exit $?
    exit 1
    ;;
  os)
    echo "os NOT YET IMPLEMENTED!"
    exit 1
    ;;
  plugin)
    echo "plugin NOT YET IMPLEMENTED!"
    exit 1
    ;;
  *)
    echo "Invalid component: $COMPONENT"
    exit 1
    ;;
esac
