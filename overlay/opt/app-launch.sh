#!/bin/bash

${YIO_HOME}/scripts/wifi-copy-config.sh

${YIO_HOME}/scripts/firstrun.sh

export QT_QPA_EVDEV_TOUCHSCREEN_PARAMETERS=/dev/input/event0:rotate=90:invertx
export QT_QPA_EGLFS_PHYSICAL_WIDTH=46
export QT_QPA_EGLFS_PHYSICAL_HEIGHT=76
export QT_QPA_EGLFS_FORCE888=1

${YIO_HOME}/app/remote &
