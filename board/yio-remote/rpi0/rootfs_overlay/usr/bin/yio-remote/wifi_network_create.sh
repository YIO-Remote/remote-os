#!/bin/bash

#check if there is a file
mkdir -p /etc/wpa_supplicant
if [ -e /etc/wpa_supplicant/wpa_supplicant-wlan0.conf ]; then

    # re-create a configuration file
    echo "ctrl_interface=/var/run/wpa_supplicant
ap_scan=1

network={
    key_mgmt=WPA-PSK
    ssid="\"$1\""
    psk="\"$2\""
}" > /etc/wpa_supplicant/wpa_supplicant-wlan0.conf
else
    # create a configuration file
    echo "ctrl_interface=/var/run/wpa_supplicant
ap_scan=1
    
network={
    key_mgmt=WPA-PSK
    ssid="\"$1\""
    psk="\"$2\""
}" > /etc/wpa_supplicant/wpa_supplicant-wlan0.conf
fi