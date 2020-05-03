################################################################################
#
# YIO web-configurator
#
################################################################################

YIO_WEB_CONFIGURATOR_VERSION = $(call qstrip,$(BR2_PACKAGE_YIO_WEB_CONFIGURATOR_VERSION))
YIO_WEB_CONFIGURATOR_LICENSE = GPL-3.0
YIO_WEB_CONFIGURATOR_LICENSE_FILES = LICENSE
YIO_WEB_CONFIGURATOR_SITE = git://github.com/YIO-Remote/web-configurator.git

################################################################################
# CONFIGURE_CMDS
################################################################################
define YIO_WEB_CONFIGURATOR_CONFIGURE_CMDS
    (cd $(@D); npm install)
endef

################################################################################
# BUILD_CMDS
################################################################################
define YIO_WEB_CONFIGURATOR_BUILD_CMDS
    (cd $(@D); npm run build)
    (cd $(@D)/dist; echo "$(YIO_WEB_CONFIGURATOR_VERSION)" > version.txt)
endef

################################################################################
# INSTALL_TARGET_CMDS
################################################################################
define YIO_WEB_CONFIGURATOR_INSTALL_TARGET_CMDS
    $(INSTALL) -d $(TARGET_DIR)/opt/yio/web-configurator
    $(INSTALL) -m 0644 $(@D)/dist/* $(TARGET_DIR)/opt/yio/web-configurator
endef

$(eval $(generic-package))
