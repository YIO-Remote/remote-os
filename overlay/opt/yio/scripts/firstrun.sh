#!/bin/bash

#--------------------
# YIO first setup script
#--------------------
if [ -e /var/yio/firstrun ]
then
    #--------------------
    # Do some setup with services
    #--------------------
    # FIXME log error: Failed to disable unit: File /etc/systemd/system/multi-user.target.wants/dhcpcd.service: Read-only file system
    systemctl disable dhcpcd.service
    # FIXME log error: Failed to disable unit: File /etc/systemd/system/multi-user.target.wants/lighttpd.service: Read-only file system
    systemctl disable lighttpd.service

    systemctl stop dhcpcd.service

    #--------------------
    # SSID to config
    #--------------------
    MACADDR=$(cat /sys/class/net/wlan0/address | tr -d ":")
    SSID="YIO-Remote-$MACADDR"

    # Note: /etc/hostname & hosts are bind mounted to /var and therefore writeable
    echo "$SSID" > /etc/hostname
    echo "127.0.0.1	localhost
127.0.0.1	$SSID" > /etc/hosts

    # FIXME log error: Could not set property: Failed to set static hostname: Read-only file system
    # systemd-hostnamed[150]: Failed to write static host name: Read-only file system
    hostnamectl set-hostname "$SSID"
    systemctl restart avahi-daemon

    # /var/yio/wificopy marker file is set in wifi-copy-config.sh which is called from app-launch.sh
    if [ -e /var/yio/wificopy ]; then
        # if there was a wifi config on the sd card, skip the first time setup
        rm /var/yio/firstrun
        # quick fix: initial reboot to settle wifi configuration
        reboot
    fi
fi
