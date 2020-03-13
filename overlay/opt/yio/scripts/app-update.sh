#!/bin/bash
#------------------------------------------------------------------------------
# YIO updater script
#
# Copyright (C) 2020 Markus Zehnder <business@markuszehnder.ch>
# Copyright (C) 2018-2020 Marton Borzak <hello@martonborzak.com>
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

# Exit on all command errors '-e' while still calling error trap '-E'
# See https://stackoverflow.com/a/35800451
set -eE
trap 'log "ERROR ${?} occured in ${0} on line ${LINENO}"' ERR

# Helper functions

log() {
  echo "$*"
  if [[ ! -z $LOGFILE ]]; then

    echo `date +%FT%T%Z` "$*" >> "$LOGFILE"
  fi
}

# TODO function to clean up in case of update error!
# We don't want to end up in an update loop trying to install a corrupt archive

#------------------------------------------------------------------------------
# Start of script

# check command line arguments
if [ $# -eq 0 ]; then
    echo "$0 [UPDATE_ARCHIVE_PATH]"
    exit 1
fi
UPDATE_FILE=$1

if [[ $(id -u) -ne 0 ]] ; then
  echo "Must be run as root"
  exit 1
fi

# verify environment
if [[ ! -f $UPDATE_FILE ]]; then
    echo "Update archive file not found: $UPDATE_FILE"
    exit 1
fi

if [[ $UPDATE_FILE != *.tar ]]; then
    echo "Only tar update archive file is supported: $UPDATE_FILE"
    exit 1
fi

if [[ -z $YIO_HOME ]]; then
  echo "YIO_HOME environment variable not set!"
  exit 1
fi

if [[ ! -d $YIO_HOME ]]; then
  echo "Installation target does not exist: $YIO_HOME"
  exit 1
fi

if [[ -z $YIO_LOG_DIR_UPDATE ]]; then
  echo "YIO_LOG_DIR_UPDATE environment variable not set!"
  exit 1
fi

# TODO check free space?

YIO_REMOTE_DIR=${YIO_HOME}/app
YIO_SPLASH_DIR=${YIO_HOME}/media/splash
# write update log into dedicated update log file
mkdir -p $YIO_LOG_DIR_UPDATE
LOGFILE=${YIO_LOG_DIR_UPDATE}/appupdate.log

echo "Writing update log file: $LOGFILE"
echo "YIO Remote App Update Log" > $LOGFILE
log "Update archive:         $UPDATE_FILE"
log "Installation directory: $YIO_REMOTE_DIR"

#------------------------------------------------------------------------------
# Start update process!
#------------------------------------------------------------------------------

if [[ -f ${YIO_SPLASH_DIR}/update.png ]]; then
    fbv -d 1 "${YIO_SPLASH_DIR}/update.png"
fi

#------------------------------------------------------------------------------
# Extract update archive to temp location
#------------------------------------------------------------------------------

# TODO (sub-) archive hash check?
tar tf "$UPDATE_FILE" > /dev/null || {
    log "Invalid tar archive: $UPDATE_FILE"
    exit 1
}

# use ${YIO_HOME} base dir for atomic file operation (/tmp might be on another partition)
TMPDIR=${YIO_HOME}/app-$(date +"%Y%m%d%H%M%S")
log "Extracting archive to temporary folder: $TMPDIR"
mkdir -p ${TMPDIR} >> $LOGFILE 2>&1

tar -xf "$UPDATE_FILE" -C ${TMPDIR} >> $LOGFILE 2>&1

if [[ -f ${TMPDIR}/hooks/pre-install.sh ]]; then
    log "Running pre-install script: ${TMPDIR}/hooks/pre-install.sh"
    ${TMPDIR}/pre-install.sh  >> $LOGFILE 2>&1
fi

# TODO keep the permission fix?
# The final tar archive should have everything set correctly!
# Unless we have cross compiled builds from Windows :-/
find ${TMPDIR} -type f -name "*.sh" -exec chmod 775 {} + >> $LOGFILE 2>&1
chmod +x ${TMPDIR}/app/remote >> $LOGFILE 2>&1

#------------------------------------------------------------------------------
# Replace old backup with the current app version
#------------------------------------------------------------------------------
YIO_BACKUP=${YIO_HOME}/app-previous

if [[ -d $YIO_BACKUP ]]; then
    rm -rf "${YIO_BACKUP}"
    log "Removed previous app backup: $YIO_BACKUP"
fi

killall -9 remote >> $LOGFILE 2>&1 || true
sleep 2

mv "$YIO_REMOTE_DIR" "$YIO_BACKUP" >> $LOGFILE 2>&1
log "Renamed current app to: $YIO_BACKUP"

#------------------------------------------------------------------------------
# Activate new app
#------------------------------------------------------------------------------
mv ${TMPDIR}/app "$YIO_REMOTE_DIR" >> $LOGFILE 2>&1
log "Update ($TMPDIR/yio-remote) is now the active app ($YIO_REMOTE_DIR)"

if [[ -f ${TMPDIR}/hooks/post-install.sh ]]; then
    log "Running post-install script: ${TMPDIR}/hooks/post-install.sh"
    ${TMPDIR}/post-install.sh >> $LOGFILE 2>&1
fi

rm -rf $TMPDIR
rm "$UPDATE_FILE"
# TODO remove metadata / markerfile
log "Deleted update archive file and temporary folder"

#TODO rather reboot? If yes: it would be a good time to check & repair file systems
log "Update finished! Launching app..."
$YIO_HOME/app-launch.sh &
