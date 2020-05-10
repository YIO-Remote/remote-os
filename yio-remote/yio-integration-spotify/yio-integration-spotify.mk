################################################################################
#
# YIO integration-spotify
#
################################################################################

# Attention: this makefile doesn't work yet for building the integration from source!
# Only the binary release installation is implemented. Source build will be included in a future release.

YIO_INTEGRATION_SPOTIFY_VERSION = $(call qstrip,$(BR2_PACKAGE_YIO_INTEGRATION_SPOTIFY_VERSION))
YIO_INTEGRATION_SPOTIFY_DEBUG = $(call qstrip,$(BR2_PACKAGE_YIO_REMOTE_DEBUG))
YIO_INTEGRATION_SPOTIFY_LICENSE = GPL-3.0
YIO_INTEGRATION_SPOTIFY_LICENSE_FILES = LICENSE

# Compute mandatory _SOURCE and _SITE from the configuration
ifeq ($(BR2_PACKAGE_YIO_REMOTE_BIN_RELEASE),y)
    ifeq ($(YIO_INTEGRATION_SPOTIFY_DEBUG),y)
        YIO_INTEGRATION_SPOTIFY_SOURCE = YIO-integration.spotify-$(YIO_INTEGRATION_SPOTIFY_VERSION)-RPi0-debug.tar
    else
        YIO_INTEGRATION_SPOTIFY_SOURCE = YIO-integration.spotify-$(YIO_INTEGRATION_SPOTIFY_VERSION)-RPi0-release.tar
    endif
    YIO_INTEGRATION_SPOTIFY_SITE = https://github.com/YIO-Remote/integration.spotify/releases/download/$(YIO_INTEGRATION_SPOTIFY_VERSION)
else
    YIO_INTEGRATION_SPOTIFY_SITE = git://github.com/YIO-Remote/integration.spotify.git
endif

################################################################################
# CONFIGURE_CMDS
################################################################################
ifeq ($(BR2_PACKAGE_YIO_REMOTE_BIN_RELEASE),y)
define YIO_INTEGRATION_SPOTIFY_CONFIGURE_CMDS
    @echo "Extracting release archive..."
    (cd $(@D); tar -xvf app.tar.gz);
endef
endif

################################################################################
# BUILD_CMDS
################################################################################

################################################################################
# INSTALL_TARGET_CMDS
################################################################################
ifeq ($(BR2_PACKAGE_YIO_REMOTE_BIN_RELEASE),y)
define YIO_INTEGRATION_SPOTIFY_INSTALL_TARGET_CMDS
    $(INSTALL) -d $(TARGET_DIR)/opt/yio/app-plugins
    $(INSTALL) -m 0644 $(@D)/app/plugins/* $(TARGET_DIR)/opt/yio/app-plugins
endef
endif

$(eval $(generic-package))
