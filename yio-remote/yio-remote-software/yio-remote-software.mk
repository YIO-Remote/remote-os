################################################################################
#
# yio-remote-software
#
################################################################################

YIO_REMOTE_SOFTWARE_VERSION = $(call qstrip,$(BR2_PACKAGE_YIO_REMOTE_SOFTWARE_VERSION))
YIO_REMOTE_SOFTWARE_DEBUG = $(call qstrip,$(BR2_PACKAGE_YIO_REMOTE_DEBUG))
YIO_REMOTE_SOFTWARE_LICENSE = GPL-3.0
YIO_REMOTE_SOFTWARE_LICENSE_FILES = LICENSE
YIO_REMOTE_SOFTWARE_DEPENDENCIES = qt5base qt5connectivity qt5graphicaleffects qt5imageformats qt5quickcontrols qt5quickcontrols2 qt5tools qt5virtualkeyboard qt5websockets yio-integrations-library
YIO_REMOTE_SOFTWARE_SITE = git://github.com/YIO-Remote/remote-software.git

ifeq ($(YIO_REMOTE_SOFTWARE_DEBUG),y)
    YIO_REMOTE_SOFTWARE_QMAKE_ARGS = "CONFIG+=debug CONFIG+=qml_debug"
else
    YIO_REMOTE_SOFTWARE_QMAKE_ARGS = "CONFIG+=release"
endif

################################################################################
# PRE_CONFIGURE_HOOKS
################################################################################

################################################################################
# CONFIGURE_CMDS
################################################################################
define YIO_REMOTE_SOFTWARE_CONFIGURE_CMDS
    @echo "Creating Makefile..."
    @mkdir -p $(@D)/build
    (cd $(@D)/build; $(TARGET_MAKE_ENV) YIO_BIN=$(@D)/bin YIO_SRC="$(STAGING_DIR)/usr/include/yio" $(HOST_DIR)/bin/qmake $(@D) $(YIO_REMOTE_SOFTWARE_QMAKE_ARGS))
    (cd $(@D)/build; $(TARGET_MAKE_ENV) YIO_BIN=$(@D)/bin YIO_SRC="$(STAGING_DIR)/usr/include/yio" $(MAKE) qmake_all)
endef

################################################################################
# BUILD_CMDS
################################################################################
define YIO_REMOTE_SOFTWARE_BUILD_CMDS
    ($(TARGET_MAKE_ENV) $(MAKE) -C $(@D)/build)
endef

################################################################################
# INSTALL_TARGET_CMDS
################################################################################
define YIO_REMOTE_SOFTWARE_INSTALL_TARGET_CMDS
    $(INSTALL) -d 0755 $(TARGET_DIR)/opt/yio/app/icons $(TARGET_DIR)/opt/yio/app/fonts $(TARGET_DIR)/opt/yio/app-plugins
    $(INSTALL) -m 0755 $(@D)/bin/remote $(TARGET_DIR)/opt/yio/app; \
    $(INSTALL) -m 0644 $(@D)/bin/*.json $(TARGET_DIR)/opt/yio/app
    $(INSTALL) -m 0644 $(@D)/build/version.txt $(TARGET_DIR)/opt/yio/app
    mv $(TARGET_DIR)/opt/yio/app/config.json $(TARGET_DIR)/opt/yio/app/config.json.def
    $(INSTALL) -m 0644 $(@D)/bin/icons/* $(TARGET_DIR)/opt/yio/app/icons
    $(INSTALL) -m 0644 $(@D)/bin/fonts/* $(TARGET_DIR)/opt/yio/app/fonts
endef

$(eval $(generic-package))
