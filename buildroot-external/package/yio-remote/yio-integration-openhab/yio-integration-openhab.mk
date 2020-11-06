################################################################################
#
# YIO integration-openhab
#
################################################################################

YIO_INTEGRATION_OPENHAB_VERSION = $(call qstrip,$(BR2_PACKAGE_YIO_INTEGRATION_OPENHAB_VERSION))
YIO_INTEGRATION_OPENHAB_DEBUG = $(call qstrip,$(BR2_PACKAGE_YIO_REMOTE_DEBUG))
YIO_INTEGRATION_OPENHAB_LICENSE = GPL-3.0
YIO_INTEGRATION_OPENHAB_LICENSE_FILES = LICENSE
YIO_INTEGRATION_OPENHAB_DEPENDENCIES = qt5base qt5connectivity qt5tools qt5websockets yio-integrations-library
YIO_INTEGRATION_OPENHAB_SITE = git://github.com/YIO-Remote/integration.openhab.git

ifeq ($(YIO_REMOTE_SOFTWARE_DEBUG),y)
    YIO_INTEGRATION_OPENHAB_QMAKE_ARGS = "CONFIG+=debug"
else
    YIO_INTEGRATION_OPENHAB_QMAKE_ARGS = "CONFIG+=release"
endif

################################################################################
# CONFIGURE_CMDS
################################################################################
define YIO_INTEGRATION_OPENHAB_CONFIGURE_CMDS
    @echo "Creating Makefile..."
    @mkdir -p $(@D)/build
    (cd $(@D)/build; $(TARGET_MAKE_ENV) YIO_BIN=$(@D)/bin YIO_SRC="$(STAGING_DIR)/usr/include/yio" $(HOST_DIR)/bin/qmake $(@D) $(YIO_INTEGRATION_OPENHAB_QMAKE_ARGS) "YIO_BUILD_VERSION = $(YIO_INTEGRATION_OPENHAB_VERSION)")
    (cd $(@D)/build; $(TARGET_MAKE_ENV) YIO_BIN=$(@D)/bin YIO_SRC="$(STAGING_DIR)/usr/include/yio" $(MAKE) qmake_all)
endef

################################################################################
# BUILD_CMDS
################################################################################
define YIO_INTEGRATION_OPENHAB_BUILD_CMDS
    ($(TARGET_MAKE_ENV) $(MAKE) -C $(@D)/build)
endef

################################################################################
# INSTALL_TARGET_CMDS
################################################################################
define YIO_INTEGRATION_OPENHAB_INSTALL_TARGET_CMDS
    $(INSTALL) -d $(TARGET_DIR)/opt/yio/app-plugins
    $(INSTALL) -m 0644 $(@D)/bin/plugins/* $(TARGET_DIR)/opt/yio/app-plugins
endef

$(eval $(generic-package))
