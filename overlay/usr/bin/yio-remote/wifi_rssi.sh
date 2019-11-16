#!/bin/bash
wpa_cli -i wlan0 signal_poll | grep "RSSI=" | cut -c6-