################################################################################
#
# Qt MQTT library
#
################################################################################

QTMQTT_VERSION = $(QT5_VERSION)
QTMQTT_DEBUG = $(call qstrip,$(BR2_PACKAGE_QTMQTT_DEBUG))
QTMQTT_LICENSE = GPL-3.0
QTMQTT_LICENSE_FILES = LICENSE
QTMQTT_DEPENDENCIES = qt5base qt5connectivity qt5tools qt5websockets
QTMQTT_SITE = git://github.com/qt/qtmqtt.git
QTMQTT_INSTALL_STAGING = YES

################################################################################
# PRE_CONFIGURE_HOOKS
################################################################################

################################################################################
# CONFIGURE_CMDS
################################################################################
define QTMQTT_CONFIGURE_CMDS
    @echo "Creating Makefile..."
	(cd $(@D); $(TARGET_MAKE_ENV) $(HOST_DIR)/bin/qmake )
endef

################################################################################
# BUILD_CMDS
################################################################################
define QTMQTT_BUILD_CMDS
	# HACK didn't find another way to compile QtMqtt 5.12.8
	mkdir -p $(@D)/include/QtMqtt
	cp $(@D)/src/mqtt/*.h $(@D)/include/QtMqtt
	# END HACK
	($(TARGET_MAKE_ENV) $(MAKE) -C $(@D))
endef

################################################################################
# INSTALL_TARGET_CMDS
################################################################################
define QTMQTT_INSTALL_STAGING_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) -C $(@D) install
endef

define QTMQTT_INSTALL_TARGET_CMDS
	cp -dpf $(STAGING_DIR)/usr/lib/libQt5Mqtt*.so.* $(TARGET_DIR)/usr/lib
endef

$(eval $(generic-package))
