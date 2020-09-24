# Makefiles used by all subprojects

# flag to skip creating the SD card image in rpi0/post-image.sh
# used for the initial buildroot build to create the toolchain used for Qt compilation
SKIP_BUILD_IMAGE=n
export SKIP_BUILD_IMAGE

include ${BR2_EXTERNAL_BUILDROOT_SUBMODULE_PATH}/package/yio-remote/yio-remote.mk
