#!/bin/bash
#
# Called from firstrun.sh if:
# - /wifisetup marker file present
# - and /wificopy marker file doesn't exist
# Output is appended to /networklist
#

wpa_cli -i wlan0 scan | grep 'OK' &> /dev/null

if [ $? == 0 ]; then
    sleep 3
    wpa_cli -i wlan0 scan_results | tail -n +2 | awk -v OFS=',' 'BEGIN {FS="\t"}; { print $3, substr($0, index($0,$5)) }'
else
    echo 'Scan failed'
fi