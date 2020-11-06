################################################################################
#
# YIO integration-spotify
#
################################################################################

YIO_INTEGRATION_SPOTIFY_VERSION = $(call qstrip,$(BR2_PACKAGE_YIO_INTEGRATION_SPOTIFY_VERSION))
YIO_INTEGRATION_SPOTIFY_DEBUG = $(call qstrip,$(BR2_PACKAGE_YIO_REMOTE_DEBUG))
YIO_INTEGRATION_SPOTIFY_LICENSE = GPL-3.0
YIO_INTEGRATION_SPOTIFY_LICENSE_FILES = LICENSE
YIO_INTEGRATION_SPOTIFY_DEPENDENCIES = qt5base qt5connectivity qt5tools yio-integrations-library
YIO_INTEGRATION_SPOTIFY_SITE = git://github.com/YIO-Remote/integration.spotify.git

ifeq ($(YIO_REMOTE_SOFTWARE_DEBUG),y)
    YIO_INTEGRATION_SPOTIFY_QMAKE_ARGS = "CONFIG+=debug"
else
    YIO_INTEGRATION_SPOTIFY_QMAKE_ARGS = "CONFIG+=release"
endif

################################################################################
# CONFIGURE_CMDS
################################################################################
define YIO_INTEGRATION_SPOTIFY_CONFIGURE_CMDS
    @echo "Creating Makefile..."
    @mkdir -p $(@D)/build
    (cd $(@D)/build; $(TARGET_MAKE_ENV) YIO_BIN=$(@D)/bin YIO_SRC="$(STAGING_DIR)/usr/include/yio" $(HOST_DIR)/bin/qmake $(@D) $(YIO_INTEGRATION_SPOTIFY_QMAKE_ARGS) "YIO_BUILD_VERSION = $(YIO_INTEGRATION_SPOTIFY_VERSION)")
    (cd $(@D)/build; $(TARGET_MAKE_ENV) YIO_BIN=$(@D)/bin YIO_SRC="$(STAGING_DIR)/usr/include/yio" $(MAKE) qmake_all)
endef

################################################################################
# BUILD_CMDS
################################################################################
define YIO_INTEGRATION_SPOTIFY_BUILD_CMDS
    ($(TARGET_MAKE_ENV) $(MAKE) -C $(@D)/build)
endef

################################################################################
# INSTALL_TARGET_CMDS
################################################################################
define YIO_INTEGRATION_SPOTIFY_INSTALL_TARGET_CMDS
    $(INSTALL) -d $(TARGET_DIR)/opt/yio/app-plugins
    $(INSTALL) -m 0644 $(@D)/bin/plugins/* $(TARGET_DIR)/opt/yio/app-plugins
endef

$(eval $(generic-package))
