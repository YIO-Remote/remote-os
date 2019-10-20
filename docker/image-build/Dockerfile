# use LTS version
FROM ubuntu:18.04

LABEL maintainer="Markus.Zehnder@trivadis.com"

ARG YIO_REMOTE_UID=1000
ARG YIO_REMOTE_GID=1000
ARG YIO_REMOTE_OS_BRANCH=dev
ARG YIO_REMOTE_SOFTWARE_BRANCH=dev
ARG YIO_WEB_CONFIGURATOR_BRANCH=master

ENV YIO_SRC=/yio-remote/src
ENV BR2_DL_DIR=/yio-remote/buildroot/dl
ENV BR2_CCACHE_DIR=/yio-remote/buildroot/ccache

# Only required if the base image isn't updated on a regular basis:
#RUN apt-get update -qq \
#    && apt-get dist-upgrade -y

RUN groupadd -g ${YIO_REMOTE_GID} yio \
    && useradd -u ${YIO_REMOTE_UID} -m -d /yio -g ${YIO_REMOTE_GID} yio

RUN apt-get update -qq \
    && apt-get install -y \
    bc \
    build-essential \
    cpio \
    g++ \
    gettext \
    patch \
    git \
    libncurses5-dev \
    libtool \
    python \
    texinfo \
    unzip \
    mc \
    nano \
    rsync \
    wget \
    whois \
	&& apt-get clean

USER yio

COPY --chown=yio:yio scripts/setup-src.sh /yio-remote/
COPY --chown=yio:yio scripts/br-source.sh /yio-remote/

# create directories where the Docker volumes will be mounted, otherwise they will be owned by root!
RUN mkdir -p /yio-remote/target /yio-remote/src /yio-remote/buildroot/dl /yio-remote/buildroot/ccache \
    && /yio-remote/setup-src.sh \
    && /yio-remote/br-source.sh \
    && rm /yio-remote/setup-src.sh \
    && rm /yio-remote/br-source.sh

# Git projects
VOLUME /yio-remote/src
# built artefacts
VOLUME /yio-remote/target
# Buildroot downloads and ccache
VOLUME /yio-remote/buildroot

WORKDIR /yio-remote

COPY --chown=yio:yio scripts/yio-remote-build.sh /usr/local/bin/

ENTRYPOINT ["yio-remote-build.sh"]
