#!/bin/bash
rm /networklist
rm /ssid
rm /firstsetup
rm /wificred
touch /wifisetup
/usr/bin/yio-remote/first-time-setup/firstrun.sh
