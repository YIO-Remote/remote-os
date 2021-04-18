#!/bin/bash

if [ -e ${YIO_CFG_OVERRIDE_DIR}/wpa_supplicant.conf ]
then
    if cmp -s ${YIO_CFG_OVERRIDE_DIR}/wpa_supplicant.conf /var/etc/wpa_supplicant/wpa_supplicant-wlan0.conf
    then
        echo "wpa_supplicant.conf in ${YIO_CFG_OVERRIDE_DIR} already copied"
    else
        echo "Using provided wpa_supplicant.conf in ${YIO_CFG_OVERRIDE_DIR}"

        # stop wifi
        systemctl stop wpa_supplicant@wlan0.service
        # copy config file
        cp ${YIO_CFG_OVERRIDE_DIR}/wpa_supplicant.conf /var/etc/wpa_supplicant/wpa_supplicant-wlan0.conf
        # restart wifi
        systemctl start wpa_supplicant@wlan0.service
        sleep 3

        touch /var/yio/wificopy
    fi
else
    echo "No wpa_supplicant.conf in ${YIO_CFG_OVERRIDE_DIR}"
    rm -f  /var/yio/wificopy
fi
