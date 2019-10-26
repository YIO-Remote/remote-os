# YIO Remote OS Repository

For details about the YIO Remote, please visit our documentation wiki: <https://github.com/YIO-Remote/documentation/wiki>

This repository contains the custom Linux OS built with [buildroot](https://www.buildroot.org/) for the YIO Remote.

## Build

Requirements:

- A Linux box or VM, otherwise Docker.
- At least 20 GB of free space.
- At least 4 GB RAM. More RAM = better file system caching.
- Fast CPU with many cores for quicker build times.
- SSD is highly recommended.
- Internet connection: packages will be downloaded during the build.
- 1+ GB microSD card
  - Future images might be larger!
  - Recommended card: Samsung EVO Plus (64 and 128GB have much higher write speed!)
  - See: [RPi microSD card performance comparison 2019](https://www.jeffgeerling.com/blog/2019/raspberry-pi-microsd-card-performance-comparison-2019)

### Docker

The easiest way to build all Qt projects and the SD card image is with the provided Docker image.

See [Docker Readme](docker/README.md).

### Linux Ubuntu 18.04.3 or newer

#### Prepare Build Environment

- If you just need a headless build VM then use the minimal [Ubuntu 18.04.3 LTS Server](http://cdimage.ubuntu.com/releases/18.04.3/release/) version.
- Some packages might already be installed depending on the version (desktop or server).

Install required tools:

1. Prepare Ubuntu for Buildroot:

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
          unzip

1. Optional: Packages for Qt development

        sudo apt-get install --no-install-recommends \
            qttools5-dev-tools

1. Optional: convenient packages for development

        sudo apt-get install \
          mc \
          nano \
          screen

1. Optional: SSH server for remote access

        sudo apt-get install openssh-server

#### Initial Checkout

    SRC_DIR=~/projects/yio

    mkdir -p ${SRC_DIR}
    cd ${SRC_DIR}
    git clone https://github.com/YIO-Remote/remote-os.git
    
    # switch to development branch
    cd remote-os
    git checkout develop
    
    # checkout buildroot (Git submodule)
    git submodule init
    git submodule update

#### Build SD Card Image

    cd ${SRC_DIR}/remote-os/buildroot
    
    make defconfig BR2_DEFCONFIG=../yio_rpi0w_defconfig
    make

Hint: redirect the `make` output log into a logfile to easy find an error during building or when using `screen` without scrollback capability:

    make 2>&1 | tee ../buildlog-$(date +"%Y%m%d_%H%M%S").log

The built SD card image can be found at: `${SRC_DIR}/remote-os/buildroot/output/images/yio-remote-sdcard.img`

#### Buildroot Commands

TODO: shortly describe the main commands (menuconfig, clean, rebuild, etc.)

## Write SD Card Image

Use [balenaEtcher](https://www.balena.io/etcher/) - available for Linux, macOS and Windows - or your favorite tool.

## Technology Research

The following technologies were / are investigated for finding an easy and automated solution to build the RPi image.

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
