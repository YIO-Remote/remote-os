[![Release](https://github.com/YIO-Remote/remote-os/workflows/Release/badge.svg)](https://github.com/YIO-Remote/remote-os/actions?query=workflow%3ARelease)

# YIO Remote OS Repository

This repository contains the custom Linux OS for the [YIO remote](https://www.yio-remote.com/) application.

YIO Remote OS is built using [Buildroot](https://buildroot.org) and tailored to running the [YIO remote software](https://github.com/YIO-Remote/remote-software) application.  
The output is a ready to use SD card image for the Raspberry Pi Zero W in the YIO remote and a cross-compile toolchain for Qt Creator.

## Supported Hardware

- [YIO remote](https://www.yio-remote.com/) (Raspberry Pi Zero-W with custom PCB)

Development boards:

- Raspberry Pi Zero-W and 3 with HDMI or DSI screen
  - Attention: for developers only, customization required, might not always work out of the box!
  - _Planned: Pimoroni Hyperpixel support_

## Getting Started

See [releases](releases) for SD card images and cross compile toolchains.

Use [balenaEtcher](https://www.balena.io/etcher/) - available for Linux, macOS and Windows - or your favorite tool.

For details about the YIO Remote, please visit our documentation wiki: <https://github.com/YIO-Remote/documentation/wiki>

## Developer Documentation

See the [doc](./doc) directory for the developer documentation.
