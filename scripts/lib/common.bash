#!/bin/false
#------------------------------------------------------------------------------
# Common helper functions
#
# Copyright (C) 2020 Markus Zehnder <business@markuszehnder.ch>
#
# This file is part of the YIO-Remote software project.
#------------------------------------------------------------------------------

YioRepos=(
    "remote-software,yio-remote-software"
    "web-configurator,yio-web-configurator"
    "integration.dock,yio-integration-dock"
    "integration.homey,yio-integration-homey"
    "integration.home-assistant,yio-integration-homeassistant"
    "integration.openhab,yio-integration-openhab"
    "integration.spotify,yio-integration-spotify"
    "integration.bangolufsen,yio-integration-bangolufsen"
    "integration.openweather,yio-integration-openweather"
    "integration.roon,yio-integration-roon"
)

#=============================================================

# Retrieve the latest release version from GitHub for the given repository.
# Parameters:
# $1: YIO GitHub repository. E.g. web-configurator, remote-software, etc.
# Output variables:
# - LATEST_RELEASE: release version. E.g. v0.1.2
getLatestRelease() {
    local response=$(curl -s "https://api.github.com/repos/YIO-Remote/${1}/releases/latest")
    LATEST_RELEASE=$(echo -e "$response" | awk -F '"' '/tag_name/{print $4}')
    if [[ -z $LATEST_RELEASE ]]; then
        echo "Error getting latest $1 release from GitHub: $response"
        exit 1
    fi
}
