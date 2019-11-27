#!/bin/bash

mkdir -p /etc/wpa_supplicant
# create a configuration file
# See: https://w1.fi/cgit/hostap/plain/wpa_supplicant/wpa_supplicant.conf
echo "ctrl_interface=/var/run/wpa_supplicant
ap_scan=1
update_config=1

network={
    key_mgmt=WPA-PSK
    ssid="\"$1\""
    psk="\"$2\""
}" > /etc/wpa_supplicant/wpa_supplicant-wlan0.conf
