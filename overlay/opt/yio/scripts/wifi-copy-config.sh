#!/bin/bash

if [ -e /boot/wpa_supplicant.conf ]
then
    # TODO check if config files differ or not: skip if same!

    echo "Using provided wpa config in /boot."

    # stop wifi
    systemctl stop wpa_supplicant@wlan0.service
    sleep 5
    # copy config file
    mkdir -p /etc/wpa_supplicant
    cp /boot/wpa_supplicant.conf /etc/wpa_supplicant/wpa_supplicant-wlan0.conf
    # restart wifi
    systemctl start wpa_supplicant@wlan0.service
    sleep 5

    touch /wificopy
else
    echo "No wpa config in /boot."
    rm -f  /wificopy
fi
