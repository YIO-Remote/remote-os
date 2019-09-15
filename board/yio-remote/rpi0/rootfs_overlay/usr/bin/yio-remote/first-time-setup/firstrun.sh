#!/bin/bash

#--------------------
# YIO first setup script
#--------------------
if [ -e /firstrun ]
then
    #--------------------
    # Do some setup with services
    #--------------------
    systemctl disable systemd-timesyncd.service
    systemctl disable dhcpcd.service
    systemctl disable lighttpd.service
    systemctl disable update.service

    systemctl stop dhcpcd.service
    systemctl stop lighttpd.service
    systemctl stop update.service

    systemctl enable shutdown.service

    #--------------------
    # write SSID to hostapd config
    #--------------------
    MACADDR=$(cat /sys/class/net/wlan0/address | tr -d ":")
    SSID="YIO-Remote-$MACADDR"
    echo "ssid=$SSID" >> /etc/hostapd/hostapd.conf
    echo "$SSID" >> /apssid

    #--------------------
    # setup hostname
    #--------------------
    echo "$SSID" > /etc/hostname
    rm /etc/hosts
    echo "127.0.0.1	localhost
127.0.0.1	$SSID" >> /etc/hosts
    hostnamectl set-hostname "$SSID"
    systemctl restart avahi-daemon

    #--------------------
    # delete firstrun file
    #--------------------
    rm /firstrun

    touch /wifisetup
fi

#--------------------
# If there's no wifi setup, launch in AP mode
#--------------------
if [[ -e /wifisetup && ! -e /wificopy ]]
then
    #--------------------
    # scan for nearby wifis
    #--------------------
    iw dev wlan0 scan >> /dev/null
    systemctl stop wpa_supplicant@wlan0.service
    killall -9 wpa_supplicant
    sleep 1
    systemctl start wpa_supplicant@wlan0.service
    sleep 1
    /usr/bin/yio-remote/wifi_network_list.sh >> /networklist

    #--------------------
    # set static IP address
    #--------------------
    rm /etc/systemd/network/20-wireless.network
    echo "[Match]" > /etc/systemd/network/20-wireless.network
    echo "Name=wlan0" >> /etc/systemd/network/20-wireless.network
    echo "" >> /etc/systemd/network/20-wireless.network
    
    echo "[Network]" >> /etc/systemd/network/20-wireless.network
    echo "Address=10.0.0.1/24" >> /etc/systemd/network/20-wireless.network

    systemctl restart systemd-networkd

    #--------------------
    # turn off wlan service
    #--------------------
    systemctl stop wpa_supplicant@wlan0.service
    killall -9 wpa_supplicant

    #--------------------
    # DHCP and DNS service
    #--------------------	
    systemctl stop systemd-resolved.service
    dnsmasq -k --conf-file=/etc/dnsmasq.conf &

    #echo "nameserver 127.0.0.1" >> /etc/resolv.conf

    #--------------------
    # launch hostapd
    #--------------------
    hostapd -B /etc/hostapd/hostapd.conf &

    #--------------------
    # start webserver
    #--------------------
    cp /etc/lighttpd/lighttpd-wifisetup.conf /etc/lighttpd/lighttpd.conf
    systemctl restart lighttpd.service

fi
