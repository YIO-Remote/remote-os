################################################################################
#
# YIO integration-openhab
#
################################################################################

# Attention: this makefile doesn't work yet for building the integration from source!
# Only the binary release installation is implemented. Source build will be included in a future release.

YIO_INTEGRATION_OPENHAB_VERSION = $(call qstrip,$(BR2_PACKAGE_YIO_INTEGRATION_OPENHAB_VERSION))
YIO_INTEGRATION_OPENHAB_DEBUG = $(call qstrip,$(BR2_PACKAGE_YIO_REMOTE_DEBUG))
YIO_INTEGRATION_OPENHAB_LICENSE = GPL-3.0
YIO_INTEGRATION_OPENHAB_LICENSE_FILES = LICENSE

# Compute mandatory _SOURCE and _SITE from the configuration
ifeq ($(BR2_PACKAGE_YIO_REMOTE_BIN_RELEASE),y)
    ifeq ($(YIO_INTEGRATION_OPENHAB_DEBUG),y)
        YIO_INTEGRATION_OPENHAB_SOURCE = YIO-integration.openhab-$(YIO_INTEGRATION_OPENHAB_VERSION)-RPi0-debug.tar
    else
        YIO_INTEGRATION_OPENHAB_SOURCE = YIO-integration.openhab-$(YIO_INTEGRATION_OPENHAB_VERSION)-RPi0-release.tar
    endif
    YIO_INTEGRATION_OPENHAB_SITE = https://github.com/YIO-Remote/integration.openhab/releases/download/$(YIO_INTEGRATION_OPENHAB_VERSION)
else
    YIO_INTEGRATION_OPENHAB_SITE = git://github.com/YIO-Remote/integration.openhab.git
endif

################################################################################
# CONFIGURE_CMDS
################################################################################
ifeq ($(BR2_PACKAGE_YIO_REMOTE_BIN_RELEASE),y)
define YIO_INTEGRATION_OPENHAB_CONFIGURE_CMDS
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
define YIO_INTEGRATION_OPENHAB_INSTALL_TARGET_CMDS
    $(INSTALL) -d $(TARGET_DIR)/opt/yio/app-plugins
    $(INSTALL) -m 0644 $(@D)/app/plugins/* $(TARGET_DIR)/opt/yio/app-plugins
endef
endif

$(eval $(generic-package))
