################################################################################
#
# rpi-bt-firmware
#
################################################################################

RPI_BT_FIRMWARE_VERSION = a4e08822e3f24a6211f6ac94bc98b7ef87700c70
RPI_BT_FIRMWARE_SITE = $(call github,RPi-Distro,bluez-firmware,$(RPI_BT_FIRMWARE_VERSION))
RPI_BT_FIRMWARE_LICENSE = PROPRIETARY
RPI_BT_FIRMWARE_LICENSE_FILES = broadcom/BCM-LEGAL.txt

define RPI_BT_FIRMWARE_INSTALL_TARGET_CMDS
	$(INSTALL) -d $(TARGET_DIR)/lib/firmware/brcm
	$(INSTALL) -m 0644 $(@D)/broadcom/*.hcd $(TARGET_DIR)/lib/firmware/brcm
endef

$(eval $(generic-package))
