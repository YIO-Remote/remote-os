#!/bin/bash
rm /networklist
rm /ssid
rm /firstsetup
rm /wificred
touch /wifisetup

# create a configuration file
rm /etc/wpa_supplicant/wpa_supplicant-wlan0.conf
echo "ctrl_interface=/var/run/wpa_supplicant
ap_scan=1" >> /etc/wpa_supplicant/wpa_supplicant-wlan0.conf

/usr/bin/yio-remote/first-time-setup/firstrun.sh
