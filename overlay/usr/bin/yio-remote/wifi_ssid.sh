#!/bin/bash
iw dev wlan0 link | awk '/SSID/ { print substr($0, index($0,$2)) }'
