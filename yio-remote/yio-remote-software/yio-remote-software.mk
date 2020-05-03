################################################################################
#
# yio-remote-software
#
################################################################################

# Attention: this makefile doesn't work yet for building yio-remote-software from source!
# Only the binary release installations are working.
# The included source build options are a preparation for a future release.

YIO_REMOTE_SOFTWARE_VERSION = $(call qstrip,$(BR2_PACKAGE_YIO_REMOTE_SOFTWARE_VERSION))
YIO_REMOTE_SOFTWARE_DEBUG = $(call qstrip,$(BR2_PACKAGE_YIO_REMOTE_DEBUG))
YIO_REMOTE_SOFTWARE_LICENSE = GPL-3.0
YIO_REMOTE_SOFTWARE_LICENSE_FILES = LICENSE
YIO_REMOTE_SOFTWARE_DEPENDENCIES = qt5base qt5connectivity qt5graphicaleffects qt5imageformats qt5quickcontrols qt5quickcontrols2 qt5tools qt5virtualkeyboard qt5websockets

# maybe useful to download integrations.library?
#YIO_REMOTE_SOFTWARE_EXTRA_DOWNLOADS

# Compute mandatory _SOURCE and _SITE from the configuration
ifeq ($(BR2_PACKAGE_YIO_REMOTE_BIN_RELEASE),y)
    ifeq ($(YIO_REMOTE_SOFTWARE_DEBUG),y)
        YIO_REMOTE_SOFTWARE_SOURCE = YIO-remote-software-$(YIO_REMOTE_SOFTWARE_VERSION)-RPi0-debug.tar
    else
        YIO_REMOTE_SOFTWARE_SOURCE = YIO-remote-software-$(YIO_REMOTE_SOFTWARE_VERSION)-RPi0-release.tar
    endif
    YIO_REMOTE_SOFTWARE_SITE = https://github.com/YIO-Remote/remote-software/releases/download/$(YIO_REMOTE_SOFTWARE_VERSION)
else ifeq ($(BR2_PACKAGE_YIO_REMOTE_CUSTOM_BIN_DIR),y)
    YIO_REMOTE_SOFTWARE_SOURCE = dummy
    ifeq ($(YIO_REMOTE_SOFTWARE_DEBUG),y)
        YIO_REMOTE_SOFTWARE_SITE = $(call qstrip,$(BR2_PACKAGE_YIO_REMOTE_CUSTOM_BIN_DIR_LOCATION))/debug
    else
        YIO_REMOTE_SOFTWARE_SITE = $(call qstrip,$(BR2_PACKAGE_YIO_REMOTE_CUSTOM_BIN_DIR_LOCATION))/release
    endif
    YIO_REMOTE_SOFTWARE_SITE_METHOD = local
# else ifeq ($(BR2_PACKAGE_YIO_REMOTE_SOFTWARE_CUSTOM_SRC_DIR),y)
#     YIO_REMOTE_SOFTWARE_SOURCE = dummy
#     YIO_REMOTE_SOFTWARE_SITE = $(call qstrip,$(BR2_PACKAGE_YIO_REMOTE_CUSTOM_SRC_DIR_LOCATION))
#     YIO_REMOTE_SOFTWARE_SITE_METHOD = local
# else ifeq ($(BR2_PACKAGE_YIO_REMOTE_SOFTWARE_CUSTOM_TARBALL),y)
#     YIO_REMOTE_SOFTWARE_TARBALL = $(call qstrip,$(BR2_PACKAGE_YIO_REMOTE_CUSTOM_TARBALL_LOCATION))
#     YIO_REMOTE_SOFTWARE_SITE = $(patsubst %/,%,$(dir $(YIO_REMOTE_SOFTWARE_TARBALL)))
#     YIO_REMOTE_SOFTWARE_SOURCE = $(notdir $(YIO_REMOTE_SOFTWARE_TARBALL))
else
    YIO_REMOTE_SOFTWARE_SITE = git://github.com/YIO-Remote/remote-software.git
endif

ifeq ($(YIO_REMOTE_SOFTWARE_DEBUG),y)
    YIO_REMOTE_SOFTWARE_QMAKE_ARGS = "CONFIG+=debug CONFIG+=qml_debug"
else
    YIO_REMOTE_SOFTWARE_QMAKE_ARGS = "CONFIG+=release"
endif

################################################################################
# PRE_CONFIGURE_HOOKS
################################################################################
# ifeq ($(BR2_PACKAGE_YIO_REMOTE_SOFTWARE_CUSTOM_SRC_DIR),y)
# define YIO_REMOTE_SOFTWARE_PRE_CONFIGURE_FIXUP
#     @rm -Rf $(@D)/build
#     @rm -f $(@D)/translations/*.qm
#     @rm -Rf $(@D)/bin
# endef

# YIO_REMOTE_SOFTWARE_PRE_CONFIGURE_HOOKS += YIO_REMOTE_SOFTWARE_PRE_CONFIGURE_FIXUP
# endif

################################################################################
# CONFIGURE_CMDS
################################################################################
ifeq ($(BR2_PACKAGE_YIO_REMOTE_BIN_RELEASE),y)
define YIO_REMOTE_SOFTWARE_CONFIGURE_CMDS
    @echo "Extracting release archive..."
    (cd $(@D); tar -xvf app.tar.gz);
endef
else ifneq ($(BR2_PACKAGE_YIO_REMOTE_CUSTOM_BIN_DIR),y)
define YIO_REMOTE_SOFTWARE_CONFIGURE_CMDS
    @if [ "$(BR2_PACKAGE_YIO_REMOTE_SOFTWARE_QT_LINGUIST)" = "y" ]; then \
        echo "Creating translation files outside qmake build..."; \
        (cd $(@D); $(TARGET_MAKE_ENV) $(HOST_DIR)/bin/lupdate remote.pro); \
        (cd $(@D); $(TARGET_MAKE_ENV) $(HOST_DIR)/bin/lrelease remote.pro); \
    fi
    @echo "Creating Makefile..."
    @mkdir -p $(@D)/build
    (cd $(@D)/build; $(TARGET_MAKE_ENV) YIO_BIN=$(@D)/bin $(HOST_DIR)/bin/qmake $(@D) $(YIO_REMOTE_SOFTWARE_QMAKE_ARGS))
    (cd $(@D)/build; $(TARGET_MAKE_ENV) YIO_BIN=$(@D)/bin $(MAKE) qmake_all)
endef
endif

################################################################################
# BUILD_CMDS
################################################################################
ifeq ($(BR2_PACKAGE_YIO_REMOTE_BIN_RELEASE),y)
define YIO_REMOTE_SOFTWARE_BUILD_CMDS
    @echo "No build required for binary GitHub release"
endef
else ifeq ($(BR2_PACKAGE_YIO_REMOTE_CUSTOM_BIN_DIR),y)
define YIO_REMOTE_SOFTWARE_BUILD_CMDS
    @echo "No build required with custom binary directory: $(YIO_REMOTE_SOFTWARE_SITE)"
endef
else
define YIO_REMOTE_SOFTWARE_BUILD_CMDS
    @echo "Using custom source directory: $(YIO_REMOTE_SOFTWARE_SITE)"
    ($(TARGET_MAKE_ENV) $(MAKE) -C $(@D)/build)
endef
endif

################################################################################
# INSTALL_TARGET_CMDS
################################################################################
ifeq ($(BR2_PACKAGE_YIO_REMOTE_BIN_RELEASE),y)
define YIO_REMOTE_SOFTWARE_INSTALL_TARGET_CMDS
    $(INSTALL) -d $(TARGET_DIR)/opt/yio/app/icons $(TARGET_DIR)/opt/yio/app/fonts $(TARGET_DIR)/opt/yio/app-plugins
    $(INSTALL) -m 0755 $(@D)/app/remote $(TARGET_DIR)/opt/yio/app
    $(INSTALL) -m 0644 $(@D)/app/*.json $(TARGET_DIR)/opt/yio/app
    mv $(TARGET_DIR)/opt/yio/app/config.json $(TARGET_DIR)/opt/yio/app/config.json.def
    $(INSTALL) -m 0644 $(@D)/app/icons/* $(TARGET_DIR)/opt/yio/app/icons
    $(INSTALL) -m 0644 $(@D)/app/fonts/* $(TARGET_DIR)/opt/yio/app/fonts
endef
else ifeq ($(BR2_PACKAGE_YIO_REMOTE_CUSTOM_BIN_DIR),y)
define YIO_REMOTE_SOFTWARE_INSTALL_TARGET_CMDS
    $(INSTALL) -d $(TARGET_DIR)/opt/yio/app/icons $(TARGET_DIR)/opt/yio/app/fonts $(TARGET_DIR)/opt/yio/app-plugins
    $(INSTALL) -m 0755 $(@D)/remote $(TARGET_DIR)/opt/yio/app
    $(INSTALL) -m 0644 $(@D)/*.json $(TARGET_DIR)/opt/yio/app
    mv $(TARGET_DIR)/opt/yio/app/config.json $(TARGET_DIR)/opt/yio/app/config.json.def
    $(INSTALL) -m 0644 $(@D)/icons/* $(TARGET_DIR)/opt/yio/app/icons
    $(INSTALL) -m 0644 $(@D)/fonts/* $(TARGET_DIR)/opt/yio/app/fonts
    $(INSTALL) -m 0644 $(@D)/plugins/* $(TARGET_DIR)/opt/yio/app-plugins
endef
else
define YIO_REMOTE_SOFTWARE_INSTALL_TARGET_CMDS
    $(INSTALL) -d $(TARGET_DIR)/opt/yio/app/icons $(TARGET_DIR)/opt/yio/app/fonts $(TARGET_DIR)/opt/yio/app-plugins
    $(INSTALL) -m 0755 $(@D)/bin/remote $(TARGET_DIR)/opt/yio/app; \
    $(INSTALL) -m 0644 $(@D)/*.json $(TARGET_DIR)/opt/yio/app
    mv $(TARGET_DIR)/opt/yio/app/config.json $(TARGET_DIR)/opt/yio/app/config.json.def
    $(INSTALL) -m 0644 $(@D)/icons/* $(TARGET_DIR)/opt/yio/app/icons
    $(INSTALL) -m 0644 $(@D)/fonts/* $(TARGET_DIR)/opt/yio/app/fonts
endef
endif

$(eval $(generic-package))
