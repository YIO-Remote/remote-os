#!/bin/bash
#awk '{print int($1/3600)":"int(($1%3600)/60)":"int($1%60)}' /proc/uptime
uptime | awk -F'( |,|:)+' '{print $6,"hours,",$7,"minutes"}'
