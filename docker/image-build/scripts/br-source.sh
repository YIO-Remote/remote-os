#!/bin/bash
#
# Download Buildroot package sources for offline build and faster initial build.
#

cd ${YIO_SRC}/remote-os/buildroot \
    && make source
