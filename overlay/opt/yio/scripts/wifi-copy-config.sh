#!/bin/bash

if [ -e /boot/wpa_supplicant.conf ]
then
    if cmp -s /boot/wpa_supplicant.conf /etc/wpa_supplicant/wpa_supplicant-wlan0.conf
    then
        echo "wpa_supplicant.conf in /boot already copied"
    else
        echo "Using provided wpa_supplicant.conf in /boot"

        # stop wifi
        systemctl stop wpa_supplicant@wlan0.service
        sleep 5
        # copy config file
        # FIXME(zehnm) re-configure wpa_supplicant to use /data/etc/wpa_supplicant-wlan0.conf: /etc is no longer writeable!
        mkdir -p /etc/wpa_supplicant
        cp /boot/wpa_supplicant.conf /etc/wpa_supplicant/wpa_supplicant-wlan0.conf
        # restart wifi
        systemctl start wpa_supplicant@wlan0.service
        sleep 5

        mkdir -p /var/yio
        touch /var/yio/wificopy
    fi
else
    echo "No wpa_supplicant.conf in /boot"
    rm -f  /var/yio/wificopy
fi
