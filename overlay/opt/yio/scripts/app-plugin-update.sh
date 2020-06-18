#!/bin/bash
#------------------------------------------------------------------------------
# YIO app plugin updater script.
# Called from main the update.sh script and remote-software.
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
. $(dirname $0)/lib/common.bash
. $(dirname $0)/lib/util.bash

#------------------------------------------------------------------------------
# Start of script

# check command line arguments
if [ $# -eq 0 ]; then
    echo "Usage: $0 update.(version|zip|tar)"
    echo "  Updates a YIO remote app plugin with the provided update marker file or archive."
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
assertEnvVariable "YIO_PLUGIN_DIR" $YIO_PLUGIN_DIR
assertEnvVariable "YIO_LOG_DIR_UPDATE" $YIO_LOG_DIR_UPDATE

if [[ ! -d $YIO_HOME ]]; then
  echo "Installation target does not exist: $YIO_HOME"
  exit 1
fi

# TODO check free space?

YIO_SPLASH_DIR=${YIO_MEDIA_DIR}/splash
# write update log into dedicated update log file
mkdir -p $YIO_LOG_DIR_UPDATE
LOGFILE=${YIO_LOG_DIR_UPDATE}/plugin-update.log

echo "Writing update log file: $LOGFILE"
echo "YIO Remote App Plugin Update Log" > $LOGFILE
log "Update archive:         $UPDATE_FILE"
log "Installation directory: $YIO_PLUGIN_DIR"

#------------------------------------------------------------------------------
# Start update process!
#------------------------------------------------------------------------------

ensureScreenIsOn "${YIO_SPLASH_DIR}/update.png"

#------------------------------------------------------------------------------
# Extract update archive to temp location
#------------------------------------------------------------------------------

# use ${YIO_HOME} base dir for atomic file operation (/tmp might be on another partition)
TMPDIR=${YIO_HOME}/app-plugin-$(date +"%Y%m%d%H%M%S")
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

cd ${TMPDIR}
if [[ ! -f md5sums || ! -f app.tar.gz ]]; then
    log "Invalid app plugin update archive: $UPDATE_FILE"
    exit 1
fi

md5sum -c md5sums >> $LOGFILE 2>&1
gunzip -c app.tar.gz | tar -x >> $LOGFILE 2>&1
#cp version.txt app/ >> $LOGFILE 2>&1
rm app.tar.gz

if [[ ! -d ${TMPDIR}/app/plugins ]]; then
    log "Missing plugins folder in app plugin update archive: $UPDATE_FILE"
    exit 1
fi

if [[ -f ${TMPDIR}/hooks/pre-install.sh ]]; then
    log "Running pre-install script: ${TMPDIR}/hooks/pre-install.sh"
    ${TMPDIR}/pre-install.sh  >> $LOGFILE 2>&1
fi

#------------------------------------------------------------------------------
# Replace old backup with the current app version
#------------------------------------------------------------------------------
log "Stopping remote app..."
killall -9 remote >> $LOGFILE 2>&1 && sleep 2 || true
#stopService app >> $LOGFILE 2>&1#

#fbv -d 1 "${YIO_SPLASH_DIR}/update.png"

if [[ -d $YIO_PLUGIN_DIR ]]; then
  YIO_BACKUP=${YIO_HOME}/app-plugins-previous

  if [[ -d $YIO_BACKUP ]]; then
      log "Removing previous app plugins backup: '$YIO_BACKUP'"
      rm -rf "${YIO_BACKUP}" >> $LOGFILE 2>&1
  fi

  log "Backing up current plugins to: '$YIO_BACKUP'"
  cp -r "$YIO_PLUGIN_DIR" "$YIO_BACKUP" >> $LOGFILE 2>&1
else
  log "Remote app plugin directory doesn't exist: '$YIO_PLUGIN_DIR'. Skipping backup."
fi

mkdir -p $YIO_PLUGIN_DIR >> $LOGFILE 2>&1

#------------------------------------------------------------------------------
# Activate new plugin
#------------------------------------------------------------------------------
mv ${TMPDIR}/app/plugins/* "$YIO_PLUGIN_DIR" >> $LOGFILE 2>&1
log "Update ($TMPDIR) is now available in the plugin directory ($YIO_PLUGIN_DIR)"

if [[ -f ${TMPDIR}/hooks/post-install.sh ]]; then
    log "Running post-install script: ${TMPDIR}/hooks/post-install.sh"
    ${TMPDIR}/post-install.sh >> $LOGFILE 2>&1
fi

log "Deleting update archive files and temporary folder"
rm -rf $TMPDIR >> $LOGFILE 2>&1
rm "$UPDATE_FILE" >> $LOGFILE 2>&1
if [[ -f $MARKER_FILE ]]; then
  rm -f $MARKER_FILE
fi

fbv -d 1 "${YIO_SPLASH_DIR}/splash.png"

#TODO rather reboot? If yes: it would be a good time to check & repair file systems
log "Update finished! Launching app..."

# 'systemctl start app' doesn't work reliably!?
# startService app
$YIO_HOME/app-launch.sh >> /dev/null 2>&1
