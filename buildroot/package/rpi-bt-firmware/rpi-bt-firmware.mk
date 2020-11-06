################################################################################
#
# rpi-bt-firmware
#
################################################################################

RPI_BT_FIRMWARE_VERSION = 929b7af9c43e7edc8b289435a9981b240f47b218
RPI_BT_FIRMWARE_SITE = $(call github,RPi-Distro,bluez-firmware,$(RPI_BT_FIRMWARE_VERSION))
RPI_BT_FIRMWARE_LICENSE = PROPRIETARY
RPI_BT_FIRMWARE_LICENSE_FILES = broadcom/BCM-LEGAL.txt

define RPI_BT_FIRMWARE_INSTALL_TARGET_CMDS
	$(INSTALL) -d $(TARGET_DIR)/lib/firmware/brcm
	$(INSTALL) -m 0644 $(@D)/broadcom/*.hcd $(TARGET_DIR)/lib/firmware/brcm
endef

$(eval $(generic-package))
