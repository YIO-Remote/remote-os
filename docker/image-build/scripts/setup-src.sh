#!/bin/bash
#
# Setup YIO-remote project:
# - download Git repositories
# - prepare Buildroot with YIO-remote configuration
#

# quick and dirty for now...
mkdir -p ${YIO_SRC} \
    && cd ${YIO_SRC} \
    && git clone https://github.com/YIO-Remote/remote-software.git \
    && cd remote-software \
    && git checkout $YIO_REMOTE_SOFTWARE_BRANCH \
    && cd .. \
    && git clone https://github.com/YIO-Remote/web-configurator.git \
    && cd web-configurator \
    && git checkout $YIO_WEB_CONFIGURATOR_BRANCH \
    && cd .. \
    && git clone https://github.com/YIO-Remote/remote-os.git \
    && cd remote-os \
    && git checkout $YIO_REMOTE_OS_BRANCH
