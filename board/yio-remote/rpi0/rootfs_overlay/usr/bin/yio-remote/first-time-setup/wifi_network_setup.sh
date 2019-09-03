#!/bin/bash

#--------------------
# Create WPA supplicant file
#--------------------
# delete existing configuration file
rm -rf /etc/wpa_supplicant/wpa_supplicant-wlan0.conf

# create a configuration file
echo "ctrl_interface=/var/run/wpa_supplicant
ap_scan=1

network={
    key_mgmt=WPA-PSK
    ssid="\"$1\""
    psk="\"$2\""
}" >> /etc/wpa_supplicant/wpa_supplicant-wlan0.conf

echo "{\"ssid\":\"$1\",\"password\":\"$2\"}" > /wificred 

#--------------------
# Stop wireless AP
#--------------------	
killall -9 hostapd

#--------------------
# DHCP and DNS service
#--------------------	
killall -9 dnsmasq

#--------------------
# set dynamic IP address
#--------------------
rm /etc/systemd/network/20-wireless.network
echo "[Match]
Name=wlan0

[Network]
DHCP=yes" >> /etc/systemd/network/20-wireless.network

#systemctl daemon-reload
systemctl restart systemd-networkd
sleep 1
systemctl restart systemd-resolved
sleep 1

#--------------------
# Enable Wi-Fi
#--------------------
systemctl restart wpa_supplicant@wlan0.service
sleep 1

#--------------------
# Change webserver config
#--------------------
#systemctl stop lighttpd.service
cp /etc/lighttpd/lighttpd-config.conf /etc/lighttpd/lighttpd.conf
systemctl restart lighttpd.service

rm /wifisetup
touch /firstsetup
