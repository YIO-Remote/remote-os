################################################################################
#
# yio-remote
#
################################################################################

# Variable for other YIO packages to use
YIO_REMOTE_DEBUG = $(call qstrip,$(BR2_PACKAGE_YIO_REMOTE_DEBUG))

include ../yio-remote/yio-remote-software/yio-remote-software.mk
include ../yio-remote/yio-web-configurator/yio-web-configurator.mk

include ../yio-remote/yio-integration-dock/yio-integration-dock.mk
include ../yio-remote/yio-integration-homeassistant/yio-integration-homeassistant.mk
include ../yio-remote/yio-integration-homey/yio-integration-homey.mk
include ../yio-remote/yio-integration-spotify/yio-integration-spotify.mk
include ../yio-remote/yio-integration-bangolufsen/yio-integration-bangolufsen.mk
include ../yio-remote/yio-integration-openhab/yio-integration-openhab.mk
include ../yio-remote/yio-integration-openweather/yio-integration-openweather.mk
include ../yio-remote/yio-integration-roon/yio-integration-roon.mk
