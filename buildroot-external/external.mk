# Makefiles used by all subprojects

# flag to skip creating the SD card image
# used for the initial buildroot build to create the toolchain used for Qt compilation
SKIP_BUILD_IMAGE=n
export SKIP_BUILD_IMAGE

include $(sort $(wildcard $(BR2_EXTERNAL_YIOS_PATH)/package/*/*.mk))
