################################################################################
#
# yio-remote
#
################################################################################

YIO_REMOTE_VERSION = $(call qstrip,$(BR2_PACKAGE_YIO_REMOTE_VERSION))
YIO_REMOTE_DEBUG = $(call qstrip,$(BR2_PACKAGE_YIO_REMOTE_DEBUG))
YIO_REMOTE_LICENSE = GPL-3.0
YIO_REMOTE_LICENSE_FILES = LICENSE.txt
YIO_REMOTE_DEPENDENCIES = qt5base qt5connectivity qt5graphicaleffects qt5imageformats qt5quickcontrols qt5quickcontrols2 qt5tools qt5virtualkeyboard qt5websockets

# maybe useful to download plugin sources?
#YIO_REMOTE_EXTRA_DOWNLOADS

# Compute mandatory _SOURCE and _SITE from the configuration
ifeq ($(BR2_PACKAGE_YIO_REMOTE_CUSTOM_BIN_DIR),y)
    YIO_REMOTE_SOURCE = dummy
    ifeq ($(YIO_REMOTE_DEBUG),y)
        YIO_REMOTE_SITE = $(call qstrip,$(BR2_PACKAGE_YIO_REMOTE_CUSTOM_BIN_DIR_LOCATION))/debug
    else
        YIO_REMOTE_SITE = $(call qstrip,$(BR2_PACKAGE_YIO_REMOTE_CUSTOM_BIN_DIR_LOCATION))/release
    endif
    YIO_REMOTE_SITE_METHOD = local
else ifeq ($(BR2_PACKAGE_YIO_REMOTE_CUSTOM_SRC_DIR),y)
    YIO_REMOTE_SOURCE = dummy
    YIO_REMOTE_SITE = $(call qstrip,$(BR2_PACKAGE_YIO_REMOTE_CUSTOM_SRC_DIR_LOCATION))
    YIO_REMOTE_SITE_METHOD = local
else ifeq ($(BR2_PACKAGE_YIO_REMOTE_CUSTOM_TARBALL),y)
    YIO_REMOTE_TARBALL = $(call qstrip,$(BR2_PACKAGE_YIO_REMOTE_CUSTOM_TARBALL_LOCATION))
    YIO_REMOTE_SITE = $(patsubst %/,%,$(dir $(YIO_REMOTE_TARBALL)))
    YIO_REMOTE_SOURCE = $(notdir $(YIO_REMOTE_TARBALL))
else
    YIO_REMOTE_SOURCE = $(YIO_REMOTE_VERSION).tar.gz
    YIO_REMOTE_SITE = https://github.com/YIO-Remote/remote-software/archive
endif

ifeq ($(YIO_REMOTE_DEBUG),y)
    YIO_REMOTE_QMAKE_ARGS = "CONFIG+=debug CONFIG+=qml_debug"
else
    YIO_REMOTE_QMAKE_ARGS = "CONFIG+=release"
endif

################################################################################
# PRE_CONFIGURE_HOOKS
################################################################################
ifeq ($(BR2_PACKAGE_YIO_REMOTE_CUSTOM_SRC_DIR),y)
define YIO_REMOTE_PRE_CONFIGURE_FIXUP
    @rm -Rf $(@D)/build
    @rm -f $(@D)/translations/*.qm
    @rm -Rf $(@D)/bin
endef

YIO_REMOTE_PRE_CONFIGURE_HOOKS += YIO_REMOTE_PRE_CONFIGURE_FIXUP
endif

################################################################################
# CONFIGURE_CMDS
################################################################################
ifneq ($(BR2_PACKAGE_YIO_REMOTE_CUSTOM_BIN_DIR),y)
define YIO_REMOTE_CONFIGURE_CMDS
    @if [ "$(BR2_PACKAGE_YIO_REMOTE_QT_LINGUIST)" = "y" ]; then \
        echo "Creating translation files outside qmake build..."; \
        (cd $(@D); $(TARGET_MAKE_ENV) $(HOST_DIR)/bin/lupdate remote.pro); \
        (cd $(@D); $(TARGET_MAKE_ENV) $(HOST_DIR)/bin/lrelease remote.pro); \
    fi
    @echo "Creating Makefile..."
    @mkdir -p $(@D)/build
    (cd $(@D)/build; $(TARGET_MAKE_ENV) YIO_BIN=$(@D)/bin $(HOST_DIR)/bin/qmake $(@D) $(YIO_REMOTE_QMAKE_ARGS))
    (cd $(@D)/build; $(TARGET_MAKE_ENV) YIO_BIN=$(@D)/bin $(MAKE) qmake_all)
endef
endif

################################################################################
# BUILD_CMDS
################################################################################
ifeq ($(BR2_PACKAGE_YIO_REMOTE_CUSTOM_BIN_DIR),y)
define YIO_REMOTE_BUILD_CMDS
    @echo "Using custom binary directory: $(YIO_REMOTE_SITE)"
endef
else
define YIO_REMOTE_BUILD_CMDS
    @echo "Using custom source directory: $(YIO_REMOTE_SITE)"
    ($(TARGET_MAKE_ENV) $(MAKE) -C $(@D)/build)
endef
endif

################################################################################
# INSTALL_TARGET_CMDS
################################################################################
ifeq ($(BR2_PACKAGE_YIO_REMOTE_CUSTOM_BIN_DIR),y)
define YIO_REMOTE_INSTALL_TARGET_CMDS
    $(INSTALL) -d $(TARGET_DIR)/usr/bin/yio-remote/icons $(TARGET_DIR)/usr/bin/yio-remote/fonts $(TARGET_DIR)/usr/bin/yio-remote/plugins
    $(INSTALL) -m 0755 $(@D)/remote $(TARGET_DIR)/usr/bin/yio-remote
    $(INSTALL) -m 0644 $(@D)/*.json $(TARGET_DIR)/usr/bin/yio-remote
    mv $(TARGET_DIR)/usr/bin/yio-remote/config.json $(TARGET_DIR)/usr/bin/yio-remote/config.json.def
    $(INSTALL) -m 0644 $(@D)/icons/* $(TARGET_DIR)/usr/bin/yio-remote/icons
    $(INSTALL) -m 0644 $(@D)/fonts/* $(TARGET_DIR)/usr/bin/yio-remote/fonts
    $(INSTALL) -m 0644 $(@D)/plugins/* $(TARGET_DIR)/usr/bin/yio-remote/plugins
endef
else
define YIO_REMOTE_INSTALL_TARGET_CMDS
    $(INSTALL) -d $(TARGET_DIR)/usr/bin/yio-remote/icons $(TARGET_DIR)/usr/bin/yio-remote/fonts $(TARGET_DIR)/usr/bin/yio-remote/plugins
    @if [ -f $(@D)/bin/remote ]; then \
        $(INSTALL) -m 0755 $(@D)/bin/remote $(TARGET_DIR)/usr/bin/yio-remote; \
    else \
        echo "Old master branch hack until dev is merged"; \
        $(INSTALL) -m 0755 $(@D)/build/remote $(TARGET_DIR)/usr/bin/yio-remote; \
    fi
    $(INSTALL) -m 0644 $(@D)/*.json $(TARGET_DIR)/usr/bin/yio-remote
    mv $(TARGET_DIR)/usr/bin/yio-remote/config.json $(TARGET_DIR)/usr/bin/yio-remote/config.json.def
    $(INSTALL) -m 0644 $(@D)/icons/* $(TARGET_DIR)/usr/bin/yio-remote/icons
    $(INSTALL) -m 0644 $(@D)/fonts/* $(TARGET_DIR)/usr/bin/yio-remote/fonts
    #$(INSTALL) -m 0644 $(@D)/plugins/* $(TARGET_DIR)/usr/bin/yio-remote/plugins
endef
endif

$(eval $(generic-package))
