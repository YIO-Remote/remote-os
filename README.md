# YIO Remote OS Repository

For details about the YIO Remote, please visit our documentation repository which can be found under
<https://github.com/YIO-Remote/documentation>

This repository contains the custom Linux OS built with [buildroot](https://www.buildroot.org/) for the YIO Remote.

## Build

### Prepare Build Environment

#### Linux

1. Prepare Ubuntu for buildroot:

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

2. Checkout sources:

        SRC_DIR=~/projects/yio
        
        mkdir -p ${SRC_DIR}
        cd ${SRC_DIR}
        git clone https://github.com/YIO-Remote/remote-os.git

#### macOS

TODO

### Build SD Card Image

#### Initial Checkout

        cd ${SRC_DIR}
        cd remote-os
        git checkout develop
        cd buildroot
        git submodule init
        git submodule update

        # TODO git checkout required? Haven't used git submodules before...
        cd buildroot
        git checkout 2019.08.1
        cd ..

#### Build Image

        cd ${SRC_DIR}/remote-os/buildroot
        
        make defconfig BR2_DEFCONFIG=../yio_rpi0w_defconfig
        make 2>&1 | tee buildlog-$(date +"%Y%m%d_%H%M%S").txt
