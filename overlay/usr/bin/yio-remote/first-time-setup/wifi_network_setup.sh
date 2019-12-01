#!/bin/bash

#--------------------
# Create WPA supplicant file
#--------------------
# (re-)create a configuration file
mkdir -p /etc/wpa_supplicant
echo "ctrl_interface=/var/run/wpa_supplicant
ap_scan=1
update_config=1

network={
    key_mgmt=WPA-PSK
    ssid="\"$1\""
    psk="\"$2\""
}" > /etc/wpa_supplicant/wpa_supplicant-wlan0.conf

# FIXME write complete & valid json structure to /wificred
echo "{\"ssid\":\"$1\",\"password\":\"$2\"," > /wificred
echo "$1" > /ssid 

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
echo "[Match]
Name=wlan0

[Network]
DHCP=yes" > /etc/systemd/network/20-wireless.network

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
rm -f /wifisetup
touch /firstsetup

# we are called from wifi.php at the last step of the WiFi setup process:
# once the server cfg is changed no further interactions are possible in the setup!
cp /etc/lighttpd/lighttpd-config.conf /etc/lighttpd/lighttpd.conf
systemctl reload lighttpd.service
