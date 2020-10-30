################################################################################
#
# yio-remote
#
################################################################################

# Variable for other YIO packages to use
YIO_REMOTE_DEBUG = $(call qstrip,$(BR2_PACKAGE_YIO_REMOTE_DEBUG))

include $(sort $(wildcard $(BR2_EXTERNAL_BUILDROOT_SUBMODULE_PATH)/package/yio-remote/*/*.mk))