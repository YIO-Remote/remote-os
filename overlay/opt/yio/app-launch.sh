#!/bin/bash
. /etc/profile.d/yio.sh

${YIO_SCRIPT_DIR}/wifi-copy-config.sh

${YIO_SCRIPT_DIR}/firstrun.sh

export QT_QPA_EVDEV_TOUCHSCREEN_PARAMETERS=/dev/input/event0:rotate=90:invertx
export QT_QPA_EGLFS_PHYSICAL_WIDTH=46
export QT_QPA_EGLFS_PHYSICAL_HEIGHT=76
export QT_QPA_EGLFS_FORCE888=1

# check if something went wrong during the last app update
if [[ ! -d $YIO_APP_DIR ]] && [[ -d ${YIO_HOME}/app-previous ]]; then
    echo "App directory missing '$YIO_APP_DIR'! Restoring previous app version: ${YIO_HOME}/app-previous"
    mv ${YIO_HOME}/app-previous $YIO_APP_DIR
fi

${YIO_APP_DIR}/remote &
