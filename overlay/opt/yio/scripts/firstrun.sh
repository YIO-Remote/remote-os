#!/bin/bash

#--------------------
# YIO first setup script
#--------------------
if [ -e /firstrun ]
then
    #--------------------
    # Do some setup with services
    #--------------------
    systemctl disable dhcpcd.service
    systemctl disable lighttpd.service

    systemctl stop dhcpcd.service

    #--------------------
    # SSID to config
    #--------------------
    MACADDR=$(cat /sys/class/net/wlan0/address | tr -d ":")
    SSID="YIO-Remote-$MACADDR"

    echo "$SSID" > /etc/hostname
    echo "127.0.0.1	localhost
#127.0.0.1	$SSID" > /etc/hosts
    hostnamectl set-hostname "$SSID"
    systemctl restart avahi-daemon

    # /wificopy marker file is set in wifi-copy-config.sh which is called from app-launch.sh
    if [ -e /wificopy ]; then
        # if there was a wifi config on the sd card, skip the first time setup
        rm /firstrun
        # quick fix: initial reboot to settle wifi configuration
        reboot
    fi
fi
