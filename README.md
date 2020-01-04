# YIO Remote OS Repository

For details about the YIO Remote, please visit our documentation wiki: <https://github.com/YIO-Remote/documentation/wiki>

This repository contains the custom Linux OS for the YIO Remote application.  
It is built with [Buildroot](https://www.buildroot.org/) and managed with [Buildroot Submodule](README_buildroot-submodule.md).

## Build

Requirements:

- A Linux box or VM, otherwise Docker.
- At least 20 GB of free space. A SSD is highly recommended.
- At least 4 GB RAM. More RAM = better file system caching.
- Fast CPU. More cores = quicker build times.
- Internet connection: packages will be downloaded during the build.
- 1+ GB microSD card
  - Future images might be larger!
  - Recommended card: Samsung EVO Plus (64 and 128GB have much higher write speed!)
  - See: [RPi microSD card performance comparison 2019](https://www.jeffgeerling.com/blog/2019/raspberry-pi-microsd-card-performance-comparison-2019)

### Docker

If you don't have a Linux machine then the easiest way to build all Qt projects and the SD card image is with the provided Docker image.

Features:

- Buildroot build and output directories are stored in a Docker Volume due to hard links performance reasons.
- Binary outputs are copied to bind mounted directory on the host.
- YIO Remote projects can be bind mounted from the host or stored in a Docker Volume.
- A convenient build script handles all common build tasks (single project builds, full build, Git operations, etc.).

See dedicated [Docker Readme](docker/README.md) for further information.

### Linux

The build process has been tested on Ubuntu 18.04.3, 19.04 and 19.10. Other Linux distributions should work as well.

#### Prepare Build Environment

The minimal [Ubuntu 18.04.3 LTS Server](http://cdimage.ubuntu.com/releases/18.04.3/release/) version is well suited for a headless build VM. Use a desktop version if the VM should also be used for Qt development with Qt Creator.

Install required tools:

1. Prepare Ubuntu to build the Buildroot toolchain:

        sudo apt-get install \
          build-essential \
          g++ \
          gettext \
          patch \
          git \
          libncurses5-dev \
          libtool \
          python \
          texinfo \
          unzip \
          screen \
          openssh-server

   The system is now ready to compile Buildroot and build the base Linux image for YIO.

2. Optional: Qt Linguist.
   Qt Linguist is required to compile language files in *remote-software* before cross compilation.
   - Unfortunately there's no standalone package of the required command line tools `lupdate` and `lrelease`. Therefore the complete Qt development environment needs to be installed!
   - Attention: only use *apt* to install Qt on Ubuntu 19.10 or newer! Otherwise the Qt version is too old and the command line tools might be incompatible. Use the [Qt online installer](https://www.qt.io/download-open-source) instead.

            sudo apt-get install \
                qttools5-dev-tools qt5-default

3. Optional: dependencies for Qt development and building Linux target in Qt Creator:

        sudo apt-get install \
            libavahi-client-dev \
            libgl1-mesa-dev

#### Build Environment Variables

The following optional environment variables control where the build output and other artefacts during the build are stored:

| **Variable**             | **Description**  |
|--------------------------|------------------|
| `BUILDROOT_OUTPUT`       | Buildroot output directory. Default: ./rpi0/output          |
| `BR2_DL_DIR`             | Buildroot download directory. Default: $HOME/buildroot/dl   |
| `BR2_CCACHE_DIR`         | Buildroot ccache directory. Default: $HOME/buildroot/ccache |

#### Initial Checkout and Toolchain Build

Checkout project and build full cross compiler toolchain incl. target system:

    # define root directory for project checkout
    SRC_DIR=~/projects/yio

    mkdir -p $SRC_DIR
    cd $SRC_DIR
    git clone https://github.com/YIO-Remote/remote-os.git
    
    # switch to development branch
    cd remote-os
    git checkout feature/21-buildroot_custom-package
    
    # build full toolchain without YIO remote SD card image
    make SKIP_BUILD_IMAGE=y 

This will take at least an hour or much longer on a slower system.
The `make` command will automatically initialize the buildroot Git submodule (`git submodule init && git submodule update`).

#### Build SD Card Image

The SD card image build requires at least a YIO remote configuration file in `./rpi0/boot/config.json`. The latest version can be found in the [remote-software](https://github.com/YIO-Remote/remote-software) repository.  
Furthermore all application binaries and resources have to be put in `./overlay/usr/bin/yio-remote/`. These are the remote-software binary, integration plugins, fonts, icons, images and the web-configurator. See [build script in the Docker image](docker/yio-image/scripts/yio.sh) for a quick and dirty approach until each component will be properly released.

Once all resources are in place the build is a simple command:

    cd $SRC_DIR/remote-os
    make

Hint: redirect the `make` output log into a logfile to easy find an error during building or when using `screen` without scrollback capability:

    make 2>&1 | tee remote-os_build_$(date +"%Y%m%d_%H%M%S").log

The final SD card image will be written to: `${BUILDROOT_OUTPUT}/images/yio-remote-sdcard.img`

### Buildroot Commands

All Buildroot make commands must be executed in the `remote-os` project and *not* within the /buildroot sub-directory!
The main makefile wraps all comands and takes care of configuration handling and output directories.
Most important commands:

| **Command**              | **Description**  |
|--------------------------|------------------|
|  `make`                  | Update configuration from project's defconfig and start build. |
|  `make clean`            | Deletes all of the generated files, including build files and the generated toolchain! |
|  `make menuconfig`       | Shows the configuration menu with the project's defconfig. All changes will be written back to the project configuration.  |
|  `make linux-menuconfig` | Configure Linux kernel options. |
|  `make help`             | Shows all options. |

 The project configuration in `rpi0/defconfig` is automatically loaded and saved back depending on the Buildroot command (see [common.mk](common.mk)). Manual `make savedefconfig BR2_DEFCONFIG=...` and `make defconfig BR2_DEFCONFIG=...` commands are no longer required and automatically taken care of!

## Write SD Card Image

Use [balenaEtcher](https://www.balena.io/etcher/) - available for Linux, macOS and Windows - or your favorite tool.

## Technology Research

The following technologies were / are investigated for finding an easy and automated solution to build the RPi image.

### Build and Use external Toolchain with Buildroot

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

### Vagrant

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
