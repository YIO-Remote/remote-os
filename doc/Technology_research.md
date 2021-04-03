# Technology Research

The following technologies were / are investigated for finding an easy and automated solution to build the RPi image.

## Build and Use external Toolchain with Buildroot

A separate toolchain would speed up the build process. This can easily be achieved with [Buildroot Submodule](https://github.com/Openwide-Ingenierie/buildroot-submodule#using-buildroot-submodule-to-build-a-toolchain-separately).

A *make clean* will no longer erase the compiler toolchain and therefore speedup a new full build. Since Qt is required to build the YIO remote projects the complete Qt tools would have to be included as well to use the separate toolchain for the remote-software and -plugin projects. Therefore we are not using this feature to keep it simple and not to introduce another build dependency.

Using an external toolchain involves the following changes:

1. Dedicated Makefile for the toolchain: `Makefile.toolchain`

        PROJECT_NAME := toolchain
        include common.mk

2. A toolchain subproject with the toolchain configuration: `toolchain/defconfig`

        BR2_arm=y
        BR2_arm1176jzf_s=y
        BR2_DL_DIR="$(HOME)/buildroot/dl"
        BR2_PACKAGE_OVERRIDE_FILE="$(BR2_EXTERNAL_BUILDROOT_SUBMODULE_PATH)/local.mk"
        BR2_GLOBAL_PATCH_DIR="$(BR2_EXTERNAL_BUILDROOT_SUBMODULE_PATH)/patch"
        BR2_TOOLCHAIN_BUILDROOT_GLIBC=y
        BR2_KERNEL_HEADERS_CUSTOM_TARBALL=y
        BR2_KERNEL_HEADERS_CUSTOM_TARBALL_LOCATION="https://github.com/raspberrypi/linux/archive/raspberrypi-kernel_1.20190401-1.tar.gz"
        BR2_PACKAGE_HOST_LINUX_HEADERS_CUSTOM_4_14=y
        BR2_TOOLCHAIN_BUILDROOT_CXX=y
        BR2_INIT_NONE=y
        # BR2_PACKAGE_BUSYBOX is not set
        # BR2_TARGET_ROOTFS_TAR is not set

3. Referencing the external toolchain in the main project: `rpi0/defconfig`

        BR2_TOOLCHAIN_EXTERNAL=y
        BR2_TOOLCHAIN_EXTERNAL_PATH="$(BR2_EXTERNAL_BUILDROOT_SUBMODULE_PATH)/toolchain/output/host/usr"
        BR2_TOOLCHAIN_EXTERNAL_GCC_8=y
        BR2_TOOLCHAIN_EXTERNAL_HEADERS_4_14=y
        BR2_TOOLCHAIN_EXTERNAL_CUSTOM_GLIBC=y
        BR2_TOOLCHAIN_EXTERNAL_CXX=y

## Vagrant

Vagrant would be perfect for building the RPi image. Everything could be automated and one would only have to type `vagrant up`.

Found issues so far:

- Almost all official Linux boxes have a 'small' 10 GB disk:
  - Not enough to build the image.
  - No standard way of extending the disk, or limited to one virtualization provider (vagrant-disksize plugin).
  - Synced folders don't work because of hard links
- Serious issues with VirtualBox 6 in combination with newer Ubuntu images
  - Bootup takes 5+ minutes instead of seconds
  - Issue is something with the UART console

Vagrant might be investigated again in the future. For now the Docker Image provides an easy way to build on Linux, macOS and Windows.
