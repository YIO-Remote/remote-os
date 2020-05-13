#!/bin/bash
#------------------------------------------------------------------------------
# YIO updater script for web-configurator
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

# Exit on all command errors '-e' while still calling error trap '-E'
# See https://stackoverflow.com/a/35800451
set -eE
trap 'errorTrap ${?} ${LINENO}' ERR

# Helper functions
# TODO put common helper functions into a shared file
errorTrap() {
  log "ERROR $1 occured in $0 on line $2"

  if [[ -d $TMPDIR ]]; then
    rm -rf $TMPDIR
  fi
}

log() {
  echo "$*"
  if [[ ! -z $LOGFILE ]]; then

    echo `date +%FT%T%Z` "$*" >> "$LOGFILE"
  fi
}

assertEnvVariable() {
  if [[ -z $2 ]]; then
    echo "$1 environment variable not set!"
    exit 1
  fi
}

# TODO function to clean up in case of update error!
# We don't want to end up in an update loop trying to install a corrupt archive

#------------------------------------------------------------------------------
# Start of script

# check command line arguments
# TODO define archive file naming, this one here is copied from remote-software
# TODO add download from GitHub option
if [ $# -eq 0 ]; then
    echo "Usage: $0 update.(version|zip|tar)"
    echo "  Updates the YIO remote web-configurator with the provided update marker file or archive."
    echo "  The archive may be a zip or tar archive. See wiki for update archive format."
    echo "  The archive and optional marker file are deleted after a success update!"
    exit 1
fi

if [[ $(id -u) -ne 0 ]] ; then
  echo "Must be run as root"
  exit 1
fi

# handle update marker file which contains a reference to the update archive
if [[ $1 == *.version ]]; then
  MARKER_FILE=$1
  if [[ ! -f $MARKER_FILE ]]; then
    echo "Update marker file not found: $MARKER_FILE"
    exit 1
  fi
  UPDATE_FILE=$(cat "$MARKER_FILE" | awk '/^Update/{print $3}')
  if [[ -z $UPDATE_FILE ]]; then
    echo "Marker file doesn't contain update archive file reference!"
    exit 1
  fi
else
  UPDATE_FILE=$1
fi

# verify environment
if [[ ! -f $UPDATE_FILE ]]; then
  echo "Update archive file not found: $UPDATE_FILE"
  exit 1
fi

if [[ $UPDATE_FILE != *.tar && $UPDATE_FILE != *.zip ]]; then
  echo "Only tar and zip update archive files are supported: $UPDATE_FILE"
  exit 1
fi

assertEnvVariable "YIO_HOME" $YIO_HOME
assertEnvVariable "YIO_APP_DIR" $YIO_APP_DIR
assertEnvVariable "YIO_LOG_DIR_UPDATE" $YIO_LOG_DIR_UPDATE

if [[ ! -d $YIO_HOME ]]; then
  echo "Installation target does not exist: $YIO_HOME"
  exit 1
fi

# TODO check free space?

# write update log into dedicated update log file
mkdir -p $YIO_LOG_DIR_UPDATE
LOGFILE=${YIO_LOG_DIR_UPDATE}/web-cfg-update.log

echo "Writing update log file: $LOGFILE"
echo "YIO Web-configurator Update Log" > $LOGFILE
log "Update archive:         $UPDATE_FILE"
log "Installation directory: $YIO_APP_DIR"

#------------------------------------------------------------------------------
# Start update process!
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Extract update archive to temp location
#------------------------------------------------------------------------------

# use ${YIO_HOME} base dir for atomic file operation (/tmp might be on another partition)
TMPDIR=${YIO_HOME}/web-configurator-$(date +"%Y%m%d%H%M%S")
log "Extracting archive to temporary folder: $TMPDIR"
mkdir -p ${TMPDIR} >> $LOGFILE 2>&1

if [[ $UPDATE_FILE == *.tar ]]; then
    tar tf "$UPDATE_FILE" > /dev/null || {
        log "Invalid tar archive: $UPDATE_FILE"
        exit 1
    }

    tar -xf "$UPDATE_FILE" -C ${TMPDIR} >> $LOGFILE 2>&1
elif [[ $UPDATE_FILE == *.zip ]]; then
    unzip -l "$UPDATE_FILE" > /dev/null || {
        log "Invalid zip archive: $UPDATE_FILE"
        exit 1
    }

    unzip "$UPDATE_FILE" -d ${TMPDIR} >> $LOGFILE 2>&1
else
    log "Only tar and zip update archive files are supported: $UPDATE_FILE"
    exit 1
fi

#------------------------------------------------------------------------------
# Replace old backup with the current web-configurator version
#------------------------------------------------------------------------------
# TODO get status of lighttpd
systemctl stop lighttpd

if [[ -d $YIO_APP_DIR ]]; then
  YIO_BACKUP=${YIO_HOME}/web-configurator-previous

  if [[ -d $YIO_BACKUP ]]; then
      log "Removing previous web-configurator backup: '$YIO_BACKUP'"
      rm -rf "${YIO_BACKUP}" >> $LOGFILE 2>&1
  fi

  log "Renaming current web-configurator to: '$YIO_BACKUP'"
  mv "$YIO_APP_DIR" "$YIO_BACKUP" >> $LOGFILE 2>&1
else
  log "Remote web-configurator directory doesn't exist: '$YIO_APP_DIR'. Skipping backup."
fi

mkdir -p $YIO_APP_DIR >> $LOGFILE 2>&1

#------------------------------------------------------------------------------
# Activate new web-configurator
#------------------------------------------------------------------------------
mv ${TMPDIR}/web-configurator/* "$YIO_APP_DIR" >> $LOGFILE 2>&1
log "Update ($TMPDIR/yio-remote) is now the active web-configurator ($YIO_APP_DIR)"

log "Deleting update archive files and temporary folder"
rm -rf $TMPDIR >> $LOGFILE 2>&1
rm "$UPDATE_FILE" >> $LOGFILE 2>&1
if [[ -f $MARKER_FILE ]]; then
  rm -f $MARKER_FILE
fi

log "Update finished!"

# TODO restart lighttpd if it was started 
log "Re-launching httpd..."
