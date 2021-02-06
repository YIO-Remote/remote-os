[![Release](https://github.com/YIO-Remote/remote-os/workflows/Release/badge.svg)](https://github.com/YIO-Remote/remote-os/actions?query=workflow%3ARelease)

# YIO Remote OS Repository

This repository contains the custom Linux OS for the [YIO remote](https://www.yio-remote.com/) application.

YIO Remote OS is built using [Buildroot](https://buildroot.org) and tailored to running the [YIO remote software](https://github.com/YIO-Remote/remote-software) application.  
The output is a ready to use SD card image for the Raspberry Pi Zero W in the YIO remote and a cross-compile toolchain for Qt Creator.

## Supported Hardware

- [YIO remote](https://www.yio-remote.com/) (Raspberry Pi Zero-W with custom PCB)
- _Planned: regular Raspberry Pi with HDMI / Hyperpixel_

## Getting Started

See [releases](releases) for SD card images and cross compile toolchains.

Use [balenaEtcher](https://www.balena.io/etcher/) - available for Linux, macOS and Windows - or your favorite tool.

For details about the YIO Remote, please visit our documentation wiki: <https://github.com/YIO-Remote/documentation/wiki>

## Developer

To customize remote-os it's highly recommended having experience with:

- [Buildroot](https://buildroot.org/downloads/manual/manual.html)
- Linux operating system
- Building and customizing Linux kernel
- Embedded systems
- Shell scripting
- [Kconfig](https://www.kernel.org/doc/Documentation/kbuild/kconfig-language.txt) for writing Buildroot custom packages

### Project Structure

The following tables give a short overview of the project structure. It is using the Buildroot's _br2-external_ mechanism and was inspired by the [Home Assistant Operating System project](https://github.com/home-assistant/operating-system).

See [Buildroot documentation "Keeping customizations outside of Buildroot"](hhttps://buildroot.org/downloads/manual/manual.html#outside-br-custom) for further information.

#### Main Structure

| Directory            | Description                                   |
|----------------------|-----------------------------------------------|
| `buildroot`          | Buildroot snapshot                            |
| `buildroot-external` | Externalized remote-os configuration          |
| `buildroot-patches`  | Patches for Buildroot itself                  |
| `scripts`            | Helper scripts for updating Buildroot and firmware / kernel packages |

#### Remote-OS Configuration

All board specific configuration is found under the [`buildroot-external`](buildroot-external) directory:

| Directory            | Description                                   |
|----------------------|-----------------------------------------------|
| `board`              | Target board resources                        |
| `configs`            | Buildroot board configuration                 |
| `kernel`             | Linux kernel configuration fragments          |
| `package`            | Custom Buildroot packages                     |
| `patches`            | Patches for Buildroot packages                |
| `rootfs-overlay`     | Common file system overlay files              |
| `scripts`            | Build hook scripts                            |

### Build Environment

#### Requirements

- A Linux box or VM, otherwise Docker.
- At least 20 GB of free space. A SSD is highly recommended.
- At least 4 GB RAM. More RAM = better file system caching.
- Fast CPU. More cores = quicker build times.
- Internet connection: packages will be downloaded during the build.
- 4 GB microSD card
  - Recommended card: Samsung EVO Plus (64 and 128GB have much higher write speed!)
  - See: [RPi microSD card performance comparison 2019](https://www.jeffgeerling.com/blog/2019/raspberry-pi-microsd-card-performance-comparison-2019)

#### Docker

If you don't have a Linux machine then the easiest way to build all Qt projects and the SD card image is with the provided Docker image.

Features:

- Buildroot build and output directories are stored in a Docker Volume due to performance reasons of hard links.
- Binary outputs are copied to the bind mounted directory on the host.
- YIO Remote projects can be bind mounted from the host or stored in a Docker Volume.
- A convenient build script handles all common build tasks (single project builds, full build, Git operations, etc.).

See dedicated [docker-build project](https://github.com/YIO-Remote/docker-build) for further information.

#### Linux

The build process has been tested on Ubuntu 18.04.3, and 20.04. Other Linux distributions should work as well.

##### Prepare Build Environment

The minimal [Ubuntu 18.04.3 LTS Server](http://cdimage.ubuntu.com/releases/18.04.3/release/) version is well suited for a headless build VM. Use a desktop version if the VM should also be used for Qt development with Qt Creator.

Install required tools:

1. Prepare Ubuntu to build the Buildroot toolchain and compile the YIO Qt projects:

        sudo apt-get install \
          build-essential \
          bzip2 \
          dos2unix \
          g++ \
          gdb-multiarch \
          gettext \
          git \
          libavahi-client-dev \
          libgl1-mesa-dev \
          libncurses5-dev \
          libtool \
          npm \
          patch \
          python \
          rsync \
          tar \
          texinfo \
          unzip \
          screen \
          openssh-server

   The system is now ready to compile Buildroot and build the base Linux image for YIO.

2. Optional: install Qt with the [Qt online installer](https://www.qt.io/download-open-source).

### Build SD Card Image

Checkout project:

    # define root directory for project checkout
    SRC_DIR=~/projects/yio

    mkdir -p $SRC_DIR
    cd $SRC_DIR
    git clone https://github.com/YIO-Remote/remote-os.git

Build full cross compiler toolchain with YIO remote SD card image:

    make remote

This will take at least one hour or much longer on a slower system.

> Hint: the provided build wrapper script `build.sh` redirects the `make` output into a timestamped log file.

The final SD card image will be written to: `./release/yio-remote-sdcard-$VERSION.img`

### Buildroot Commands

All Buildroot make commands should be executed in the `remote-os` project and *not* within the ./buildroot sub-directory!
The [main Makefile](Makefile) wraps all comands and takes care of configuration handling and output directories.

Wrapper Makefile commands:

| **Command**                | **Description**                                  |
|----------------------------|--------------------------------------------------|
|  `make <target>`           | Build target and keep Buildroot build artefacts. |
|  `make all`                | Build all target images. Buildroot build artefacts are deleted after each target build! |
|  `make clean`              | Delete all Buildroot build artefacts. Binary artefacts in ./release are not deleted.    |
|  `make <target>-menuconfig`| Buildroot configuration of the given target. All changes will be written back to the target board's configuration. |
|  `make help`               | Shows all options. |

Advanced Buildroot make targets can be used within the ./buildroot sub-directory but the correct `BR2_EXTERNAL` and `BR2_DEFCONFIG` options must be set manually!

> The build helper script [build.sh](build.sh) can be used to build a single board target only.

#### Examples

- Only build the [remote](buildroot-external/board/remote) target image:

      make remote

  - Buildroot output (build, image, target) is not deleted for single target builds and can be found at: `./buildroot/output`
  - Image output: `./release/yio-remote-sdcard-${VERSION}.img`
  
- Build all targets:

      make all

  - Image output: `./release/yio-${TARGET}-sdcard-${VERSION}.img`
  - Buildroot output is automatically deleted after each target build!

- Configure `remote` target:

      make remote-menuconfig

  - Configures Buildroot from the given board configuration: `./buildroot-external/configs/remote_defconfig`
  - Calls Buildroot menuconfig
  - Saves updated configuration and the old board configuration is backed up as `remote_defconfig.old`

### Build Options

#### YIO Packages

Individual YIO components can be selected or deselected within menuconfig:

  make remote-menuconfig

Navigate to: External options -> Yio remote

```
 → External options → YIO remote ──────────────────────────────────────────────
  ┌────────────────────────────── YIO remote ───────────────────────────────┐
  │  Arrow keys navigate the menu.  <Enter> selects submenus ---> (or empty │  
  │  submenus ----).  Highlighted letters are hotkeys.  Pressing <Y>        │  
  │  selects a feature, while <N> excludes a feature.  Press <Esc><Esc> to  │  
  │  exit, <?> for Help, </> for Search.  Legend: [*] feature is selected   │  
  │ ┌─────────────────────────────────────────────────────────────────────┐ │  
  │ │    --- YIO remote                                                   │ │  
  │ │    [ ]   Debug build                                                │ │  
  │ │    [ ]   Custom versions (DANGEROUS!)                               │ │  
  │ │    [*]   Remote application                                         │ │  
  │ │    [*]   Integration library                                        │ │  
  │ │    [*]   Web configurator                                           │ │  
  │ │    [*]   Integration plugins                                        │ │  
  │ │    [*]     Dock integration                                         │ │  
  │ │    [*]     Home Assistant integration                               │ │  
  │ │    [*]     Homey integration                                        │ │  
  │ │    [*]     Spotify integration                                      │ │  
  │ │    [*]     Bang & Olufsen integration                               │ │  
  │ │    [ ]     openHAB integration (UNDER DEVELOPMENT)                  │ │  
  │ │    [ ]     Roon integration (UNMAINTAINED!)                         │ │  
  │ │    [ ]     OpenWeather integration (EXPERIMENTAL!)                  │ │  
  │ └─────────────────────────────────────────────────────────────────────┘ │  
  ├─────────────────────────────────────────────────────────────────────────┤  
  │        <Select>    < Exit >    < Help >    < Save >    < Load >         │  
  └─────────────────────────────────────────────────────────────────────────┘  
```

#### Output Directories

The following optional environment variables control where the build output and other artefacts during the build are stored:

| **Variable**             | **Description**  |
|--------------------------|------------------|
| `BUILDROOT_OUTPUT`       | Buildroot output directory. Default: ./buildroot/output     |
| `BR2_DL_DIR`             | Buildroot download directory. Default: $HOME/buildroot/dl   |
| `BR2_CCACHE_DIR`         | Buildroot ccache directory. Default: $HOME/buildroot/ccache |

#### Further Options

Further `make` arguments:

| **Option**               | **Description**  |
|--------------------------|------------------|
| `BR2_JLEVEL=n`           | Adjust level of build parallelism. n = number of cores. Default: number of CPUs + 1 |

### Troubleshooting

If something doesn't work correctly, especially after changing any Buildroot configuration settings, do a clean rebuild:

  make clean
  make remote

Buildroot uses agressive caching and in many cases doesn't support incremental builds.

If you still encounter strange errors try deleting the ccache and download directories: `$HOME/buildroot/ccache` and `$HOME/buildroot/ccache`.

#### Build Errors

##### make fails while downloading package

Error symptom: a package cannot be downloaded from <http://sources.buildroot.net/> and fails after the 3rd attempt.

Cause: Buildroot source server is down or overloaded

Solution: try again the next day
