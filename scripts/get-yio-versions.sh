#!/bin/bash
#------------------------------------------------------------------------------
# Helper script to get the latest YIO component release versions from GitHub.
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

DIR="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

. $DIR/lib/common.bash

#=============================================================

usage() {
  cat << EOF

Usage:
$0 [REPO]
  Retrieves the latest YIO component release versions from GitHub.
  If REPO is specified, only the given component is checked,
  otherwise all repositories are queried.

EOF
  exit 1
}

#=============================================================

printReleaseInfo() {
    getLatestRelease $1
    echo "$1: $LATEST_RELEASE"
}

checkReleases() {
    echo "Retrieving version information from GitHub..."
    echo ""

    printReleaseInfo remote-software
    printReleaseInfo web-configurator

    for item in ${YioRepos[*]}; do
        local PROJECT=$(awk -F, '{print $1}' <<< $item)
        printReleaseInfo $PROJECT
    done
    
    echo ""
}

#=============================================================

#------------------------------------------------------------------------------
# Start of script
#------------------------------------------------------------------------------
# check command line arguments
while getopts "h" opt; do
  case ${opt} in
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
    checkReleases
else
    getLatestRelease $1
    echo "$LATEST_RELEASE"
fi
