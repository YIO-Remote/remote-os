#!/bin/bash
# -----------------------------------------------------------------------------
# Returns a list of WiFi networks.
# Format: <signal_strength>,<ssid>
# Example:
# -35.00,Guest Network
# -61.00,Unifi
# -75.00,DIRECT-gL-BRAVIA
# -----------------------------------------------------------------------------
# Called from firstrun.sh if:
# - /wifisetup marker file present
# - and /wificopy marker file doesn't exist
# Output is written to /networklist
# -----------------------------------------------------------------------------

# 'iw wlan0 scan' should always work, whereas 'wpa_cli -i wlan0 scan' is a pain to work with 
iw wlan0 scan | awk -f /usr/bin/yio-remote/wifi_network_list.awk
