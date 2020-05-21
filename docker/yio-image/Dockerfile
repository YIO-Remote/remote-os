FROM ubuntu:19.10 as base

# Labels, see: https://github.com/opencontainers/image-spec/blob/master/annotations.md
ARG BUILD_DATE
ARG VERSION
ARG REVISION
LABEL org.opencontainers.image.created=$BUILD_DATE
LABEL org.opencontainers.image.authors="markus.zehnder@trivadis.com"
LABEL org.opencontainers.image.url="https://github.com/YIO-Remote/remote-os/tree/master/docker"
LABEL org.opencontainers.image.source="https://github.com/YIO-Remote/remote-os.git"
LABEL org.opencontainers.image.version=$VERSION
LABEL org.opencontainers.image.revision=$REVISION
LABEL org.opencontainers.image.vendor="YIO"
LABEL org.opencontainers.image.title="YIO Build Image"
LABEL org.opencontainers.image.description="Buildroot cross compile image for YIO remote-os running on Raspberry Pi 0 W"
# END Labels

ARG UBUNTU_MIRROR="http://mirror.init7.net"
ARG YIO_REMOTE_UID=1000
ARG YIO_REMOTE_GID=1000

ENV YIO_SRC=/yio-remote/src
ENV BUILDROOT_OUTPUT=/yio-remote/buildroot/output
ENV BR2_DL_DIR=/yio-remote/buildroot/dl
ENV BR2_CCACHE_DIR=/yio-remote/buildroot/ccache

# Set timezone instead of UTC
ENV TZ=Europe/Zurich
# noninteractive is required to install tzdata package without user prompt
ENV DEBIAN_FRONTEND=noninteractive

# Only required if the base image isn't updated on a regular basis:
#RUN apt-get update -qq && apt-get dist-upgrade -y

RUN groupadd -g ${YIO_REMOTE_GID} yio \
    && useradd -u ${YIO_REMOTE_UID} -m -d /yio -g ${YIO_REMOTE_GID} yio

RUN sed --in-place "s@http://archive\.ubuntu\.com@$UBUNTU_MIRROR@g" /etc/apt/sources.list && \
    sed --in-place "s@http://security\.ubuntu\.com@$UBUNTU_MIRROR@g" /etc/apt/sources.list && \
    apt-get update -q \
    && apt-get install --no-install-recommends -y \
    bc \
    build-essential \
    ca-certificates \
    cpio \
    curl \
    file \
    g++ \
    gettext \
    git \
    gzip \
    libncurses5-dev \
    libssl-dev \
    libtool \
    mc \
    nano \
    npm \
    patch \
    python \
    qt5-qmake \
    rsync \
    tar \
    texinfo \
    tzdata \
    unzip \
    wget \
	&& apt-get clean \
	&& npm i npm@latest -g

# -----------------------------------------------------------------------------
# Start new stage for installing Qt
# -----------------------------------------------------------------------------

FROM base AS qtinstall

# Installing qt5 is complete overkill (it's already in the buildroot) but we need the Qt Linguist tools!
# This pulls in a whole desktop environment > 500 MB :-(
# Is there a better way to only install Qt Linguist lupdate & rupdate cmd line tools?
RUN apt-get update -q \
    && apt-get install --no-install-recommends -y \
    qttools5-dev-tools
# END overkill

# -----------------------------------------------------------------------------
# Start new layer to cherry pick required Qt linguist tools
# -----------------------------------------------------------------------------

FROM base

# HACK: get the Qt Linguist tools from the Qt installation step and their dependencies.
# Note:  ldd /usr/lib/qt5/bin/lupdate will print the required shared objects
COPY --from=qtinstall /usr/lib/qt5/bin/lupdate /usr/lib/qt5/bin/lrelease /usr/lib/qt5/bin/lconvert /usr/lib/qt5/bin/
COPY --from=qtinstall \
    /usr/lib/x86_64-linux-gnu/libQt5Xml.so* \
    /usr/lib/x86_64-linux-gnu/libQt5Core.so* \
    /usr/lib/x86_64-linux-gnu/libpcre2-16.so* \
    /usr/lib/x86_64-linux-gnu/libdouble-conversion.so* \
    # destination
    /usr/lib/x86_64-linux-gnu/

RUN rm /usr/bin/lupdate /usr/bin/lrelease /usr/bin/lconvert \
    && ln -s /usr/lib/qt5/bin/lupdate /usr/bin/lupdate \
    && ln -s /usr/lib/qt5/bin/lrelease /usr/bin/lrelease \
    && ln -s /usr/lib/qt5/bin/lconvert /usr/bin/lconvert
# END HACK

# create directories where the Docker volumes will be mounted, otherwise they will be owned by root!
RUN mkdir -p /yio-remote/target /yio-remote/src /yio-remote/buildroot/dl /yio-remote/buildroot/ccache \
    && chown -R yio:yio /yio-remote

USER yio

# Git projects
VOLUME /yio-remote/src
# built artefacts
VOLUME /yio-remote/target
# Buildroot downloads and ccache
VOLUME /yio-remote/buildroot

WORKDIR /yio-remote

COPY --chown=yio:yio scripts/yio.sh /usr/local/bin/yio

ENTRYPOINT ["/usr/local/bin/yio"]
