[![Release](https://github.com/YIO-Remote/remote-os/workflows/Release/badge.svg)](https://github.com/YIO-Remote/remote-os/actions?query=workflow%3ARelease)

# YIO Remote OS Repository

This repository contains the custom Linux OS for the YIO Remote application.  
It is built with [Buildroot](https://www.buildroot.org/) and managed with [Buildroot Submodule](README_buildroot-submodule.md).  
The output is a ready to use SD card image for the Raspberry Pi Zero W in the YIO remote and a cross-compile toolchain for Qt Creator.

For details about the YIO Remote, please visit our documentation wiki: <https://github.com/YIO-Remote/documentation/wiki>

## Build

Requirements:

- A Linux box or VM, otherwise Docker.
- At least 20 GB of free space. A SSD is highly recommended.
- At least 4 GB RAM. More RAM = better file system caching.
- Fast CPU. More cores = quicker build times.
- Internet connection: packages will be downloaded during the build.
- 4 GB microSD card
  - Recommended card: Samsung EVO Plus (64 and 128GB have much higher write speed!)
  - See: [RPi microSD card performance comparison 2019](https://www.jeffgeerling.com/blog/2019/raspberry-pi-microsd-card-performance-comparison-2019)

### Docker

If you don't have a Linux machine then the easiest way to build all Qt projects and the SD card image is with the provided Docker image.

Features:

- Buildroot build and output directories are stored in a Docker Volume due to performance reasons of hard links.
- Binary outputs are copied to the bind mounted directory on the host.
- YIO Remote projects can be bind mounted from the host or stored in a Docker Volume.
- A convenient build script handles all common build tasks (single project builds, full build, Git operations, etc.).

See dedicated [docker-build project](https://github.com/YIO-Remote/docker-build) for further information.

### Linux

The build process has been tested on Ubuntu 18.04.3, and 20.04. Other Linux distributions should work as well.

#### Prepare Build Environment

The minimal [Ubuntu 18.04.3 LTS Server](http://cdimage.ubuntu.com/releases/18.04.3/release/) version is well suited for a headless build VM. Use a desktop version if the VM should also be used for Qt development with Qt Creator.

Install required tools:

1. Prepare Ubuntu to build the Buildroot toolchain and compile the YIO Qt projects:

        sudo apt-get install \
          build-essential \
          bzip2 \
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

## Build SD Card Image

Checkout project:

    # define root directory for project checkout
    SRC_DIR=~/projects/yio

    mkdir -p $SRC_DIR
    cd $SRC_DIR
    git clone https://github.com/YIO-Remote/remote-os.git

Build full cross compiler toolchain with YIO remote SD card image:

    make

This will take at least one hour or much longer on a slower system.
The `make` command will automatically initialize the buildroot Git submodule (`git submodule init && git submodule update`).

Hint: redirect the `make` output log into a logfile to easy find an error during building or when using `screen` without or limited scrollback capability:

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

### Build Options

#### YIO Packages

Individual YIO components can be selected or deselected within menuconfig:

  make menuconfig

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
  │ │    [ ]     Roon integration (UNDER DEVELOPMENT)                     │ │  
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
| `BUILDROOT_OUTPUT`       | Buildroot output directory. Default: ./rpi0/output          |
| `BR2_DL_DIR`             | Buildroot download directory. Default: $HOME/buildroot/dl   |
| `BR2_CCACHE_DIR`         | Buildroot ccache directory. Default: $HOME/buildroot/ccache |

#### Further Options

Further `make` arguments:

| **Option**               | **Description**  |
|--------------------------|------------------|
| `SKIP_BUILD_IMAGE=y`     | Skip SD card image creation |
| `BR2_JLEVEL=n`           | Adjust level of build parallelism. n = number of cores. Default: number of CPUs + 1 |

## Write SD Card Image

Use [balenaEtcher](https://www.balena.io/etcher/) - available for Linux, macOS and Windows - or your favorite tool.

## Troubleshooting

If something doesn't work correctly, especially after changing any Buildroot configuration settings, do a clean rebuild:

  make clean
  make

Buildroot uses agressive caching and in many cases doesn't support incremental builds.

### Build Errors

#### make fails while downloading package

Error symptom: a package cannot be downloaded from <http://sources.buildroot.net/> and fails after the 3rd attempt.

Cause: Buildroot source server is down or overloaded

Solution: try again the next day
