################################################################################
#
# YIO integrations-library
#
################################################################################

YIO_INTEGRATIONS_LIBRARY_VERSION = $(call qstrip,$(BR2_PACKAGE_YIO_INTEGRATIONS_LIBRARY_VERSION))
YIO_INTEGRATIONS_LIBRARY_DEBUG = $(call qstrip,$(BR2_PACKAGE_YIO_REMOTE_DEBUG))
YIO_INTEGRATIONS_LIBRARY_SITE = git://github.com/YIO-Remote/integrations.library.git
YIO_INTEGRATIONS_LIBRARY_LICENSE = GPL-3.0
YIO_INTEGRATIONS_LIBRARY_LICENSE_FILES = LICENSE
YIO_INTEGRATIONS_LIBRARY_INSTALL_STAGING = YES
YIO_INTEGRATIONS_LIBRARY_INSTALL_TARGET = NO


################################################################################
# CONFIGURE_CMDS
################################################################################

################################################################################
# BUILD_CMDS
################################################################################

################################################################################
# INSTALL_TARGET_CMDS
################################################################################

define YIO_INTEGRATIONS_LIBRARY_INSTALL_STAGING_CMDS
    $(INSTALL) -d 0755 "$(STAGING_DIR)/usr/include/yio/integrations.library"
    $(INSTALL) -m 0644 $(@D)/*.pri "$(STAGING_DIR)/usr/include/yio/integrations.library"
	cd $(@D) && find src -type f -exec $(INSTALL) -Dm 644 "{}" "$(STAGING_DIR)/usr/include/yio/integrations.library/{}" \;
endef

$(eval $(generic-package))
