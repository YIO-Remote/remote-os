# YIO remote buildroot

## Build

### Prepare Build Environment

1. Prepare Ubuntu for buildroot:

        sudo apt-get install bison g++ flex gettext texinfo patch git-core libtool autoconf build-essential libncurses5-dev python unzip

1. Checkout sources:

        SRC_DIR=~/projects/yio

        mkdir -p ${SRC_DIR}
        cd ${SRC_DIR}
        git clone https://github.com/YIO-Remote/buildroot.git  

1. Retrieve matching Raspberry Pi kernel sources:

        RPI_KERNEL_VERSION=1.20180417-1

        mkdir -p ${SRC_DIR}/buildroot/linux_kernel
        cd ${SRC_DIR}/buildroot/linux_kernel
        wget -O - https://github.com/raspberrypi/linux/archive/raspberrypi-kernel_${RPI_KERNEL_VERSION}.tar.gz | gunzip -c > linux-raspberrypi-kernel_${RPI_KERNEL_VERSION}.tar

### Build SD Card Image

1. Set configuration for YIO:

        cd ${SRC_DIR}/buildroot
        make defconfig BR2_DEFCONFIG=buildroot_config

1. Build:

        make

## TODO

- [x] Fix WiFi setup
  - [x] Handle SSIDs with spaces (e.g. "IoT Net")
  - [x] Network scanning fails after initial boot
- [ ] Create dedicated project for YIO and pull in buildroot release
- [ ] Development (runtime) flag
  - [ ] Log messages (Rsyslog?)
  - [ ] USB gadget drivers (UART, ethernet) for easier remote access
- [ ] Create dedicated project for webserver & shell scripts.
      Buildroot should only pull in releases.
