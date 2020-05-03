################################################################################
#
# YIO integration-openweather
#
################################################################################

# Attention: this makefile doesn't work yet for building the integration from source!
# Only the binary release installation is implemented. Source build will be included in a future release.

YIO_INTEGRATION_OPENWEATHER_VERSION = $(call qstrip,$(BR2_PACKAGE_YIO_INTEGRATION_OPENWEATHER_VERSION))
YIO_INTEGRATION_OPENWEATHER_DEBUG = $(call qstrip,$(BR2_PACKAGE_YIO_REMOTE_DEBUG))
YIO_INTEGRATION_OPENWEATHER_LICENSE = GPL-3.0
YIO_INTEGRATION_OPENWEATHER_LICENSE_FILES = LICENSE

# Compute mandatory _SOURCE and _SITE from the configuration
ifeq ($(BR2_PACKAGE_YIO_REMOTE_BIN_RELEASE),y)
    ifeq ($(YIO_INTEGRATION_OPENWEATHER_DEBUG),y)
        YIO_INTEGRATION_OPENWEATHER_SOURCE = YIO-integration.openweather-$(YIO_INTEGRATION_OPENWEATHER_VERSION)-RPi0-debug.tar
    else
        YIO_INTEGRATION_OPENWEATHER_SOURCE = YIO-integration.openweather-$(YIO_INTEGRATION_OPENWEATHER_VERSION)-RPi0-release.tar
    endif
    YIO_INTEGRATION_OPENWEATHER_SITE = https://github.com/YIO-Remote/integration.openweather/releases/download/$(YIO_INTEGRATION_OPENWEATHER_VERSION)
else
    YIO_INTEGRATION_OPENWEATHER_SITE = git://github.com/YIO-Remote/integration.openweather.git
endif

################################################################################
# CONFIGURE_CMDS
################################################################################
ifeq ($(BR2_PACKAGE_YIO_REMOTE_BIN_RELEASE),y)
define YIO_INTEGRATION_OPENWEATHER_CONFIGURE_CMDS
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
define YIO_INTEGRATION_OPENWEATHER_INSTALL_TARGET_CMDS
    $(INSTALL) -d $(TARGET_DIR)/opt/yio/app-plugins
    $(INSTALL) -m 0644 $(@D)/app/plugins/* $(TARGET_DIR)/opt/yio/app-plugins
endef
endif

$(eval $(generic-package))
