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

#--------------------
# Stop wireless AP
#--------------------	
killall -9 hostapd

echo "hostpad stopped" >> /phplog

#--------------------
# DHCP and DNS service
#--------------------	
killall -9 dnsmasq

echo "dnsmasq stopped" >> /phplog

#--------------------
# set dynamic IP address
#--------------------
rm /etc/systemd/network/20-wireless.network
echo "[Match]
Name=wlan0

[Network]
DHCP=yes" >> /etc/systemd/network/20-wireless.network

systemctl restart systemd-networkd
sleep 1
systemctl restart systemd-resolved.service
sleep 1

echo "networkd and resolved started" >> /phplog

#--------------------
# Enable Wi-Fi
#--------------------
systemctl restart wpa_supplicant@wlan0.service
echo "wpa supplicant started" >> /phplog

#--------------------
# Change webserver config
#--------------------
#systemctl stop lighttpd.service
#cp /etc/lighttpd/lighttpd-config.conf /etc/lighttpd/lighttpd.conf
#systemctl start lighttpd.service

rm /wifisetup
touch /firstsetup

echo "end" >> /phplog
