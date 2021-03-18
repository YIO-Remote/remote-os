#!/bin/bash

# This script is started by systemd and profile.d environment is not set!
. /etc/profile.d/yio.sh
. /etc/profile.d/qt.sh

${YIO_SCRIPT_DIR}/wifi-copy-config.sh

${YIO_SCRIPT_DIR}/firstrun.sh

# check if something went wrong during the last app update
if [[ ! -d $YIO_APP_DIR ]] && [[ -d ${YIO_HOME}/app-previous ]]; then
    echo "App directory missing '$YIO_APP_DIR'! Restoring previous app version: ${YIO_HOME}/app-previous"
    mv ${YIO_HOME}/app-previous $YIO_APP_DIR
fi

# Do not fork! Otherwise systemd unit service doesn't work anymore
${YIO_APP_DIR}/remote
