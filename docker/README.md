# Docker Build Image for YIO-Remote

This Docker image builds the Buildroot toolchain,  cross compiles all required Qt projects from the [YIO-Remote Git repositories](https://github.com/YIO-Remote) and builds the SD card image for the Raspberry Pi Zero.

Image name: `gcr.io/yio-remote/build`

For now the image is publicly available in the gcr.io container registry and doesn't need to be built manually. Docker will automatically download it.

Further documentation can be found in the documentation wiki: <https://github.com/YIO-Remote/documentation/wiki>

## Concepts

[Buildroot](https://buildroot.org/) is easy to use with Linux, not so much with macOS and Windows. Setting up a RPi Zero cross compile toolchain is theoretically possible, but not as straightforward as on Linux.  
Therefore this Docker image acts as an universal build tool for Linux, macOS and Windows.

- Based on the official Ubuntu 19.10 image to match the Qt version 5.12.4.
- The image contains all required build tools for Buildroot in the remote-os project.
- A helper script is included to download and build all YIO-Remote projects:
  - Projects are cloned from the GitHub repositories.
  - Buildroot in the remote-os project is initialized (Git submodule).
  - The buildroot configration is applied from the remote-os project.
  - Common build commands perform the required operations on the projects.
- Cross compiliation of the Qt projects uses the already built toolchain in the remote-os project.
- Docker Volumes are used to persist data for fast builds after the initial slow build:
  - YIO-Remote Git projects.
  - Downloaded Buildroot source packages (> 900 MB).
  - Compiled Buildroot toolchain (~ 13 GB) and the Buildroot ccache (~ 1.8 GB).
- The YIO-Remote projects can be bind-mounted from the host or stored in a Docker Volume.

## Requirements

Attention Windows users: Docker Desktop for Windows uses Microsoft Hyper-V for virtualization, and Hyper-V is not compatible with Oracle VirtualBox.

- Working [Docker installation](https://docs.docker.com/install/) (tested with 19.03).
- At least 20 GB of free disk space. SSD is highly recommended!
- macOS & Windows Docker Desktop configuration:
  - Make sure your Docker VM is large enough and has enough space left.
  - Associate at least 4 GB RAM. More RAM = better file system caching.
  - Associate as many CPU cores as possible for quicker build times.
  - File sharing configured to store the build artefacts on the host and optionally mount projects.
- Internet connection:
  - Ubuntu installation packages will be downloaded during the **Docker Image build**.
  - Buildroot source packages will be downloaded during the **remote-os build** in a Docker container.

## Usage

The first initial build will take a long time (1.5 h +). This depends on internet speed, mirror state and on how powerful your PC is. It also stores around 15 GB in the Docker volumes.

After the initial build the remote-software or even the complete remote-os projects can be built within seconds or minutes!

The Docker build image can be used in various ways:

1. Wrapper script for easy interaction for commonly used build actions.  
   This hides all Docker commands.
2. Interactive shell within Docker container. See build-command *bash*.
3. Regular Docker commands for full control.
4. Docker Compose file for further integration with other images.

### Wrapper Script

The provided wrapper scripts for Windows and Bash are a convient way for interacting with the Docker image. All Docker internas are hidden to make it feel like working with a regular local tool.  
The scripts require the environment variable `YIO_BUILD_OUTPUT` for the host directory mount to store the final build artefacts.

- `yio` - Bash script for Linux and macOS:
  - Symlink the script to `/usr/local/bin` to make it accessible from anywhere.  
  E.g. `ln -s /projects/yio/remote-os/docker/yio /usr/local/bin/yio`

  - Define `YIO_BUILD_OUTPUT` in your shell environment (e.g. ~/.bashrc or ~/.profile):

        export YIO_BUILD_OUTPUT=/projects/yio/build-output

- `yio.cmd` - Windows command script:
  - Define `YIO_BUILD_OUTPUT` in your environment (Control Panel, System Properties, Advanced: Environment Variables) or temporarly define it in your current cmd session:

        SET YIO_BUILD_OUTPUT=d:/projects/yio/build-output

The scripts will automatically create the required Docker Volumes and check if Docker is running.

#### Mounting Project Folder from Host

By default the YIO Remote projects are stored in a Docker volume named `yio-projects`. The parent project folder can also be mounted from the host by defining the environment variable `YIO_BUILD_SOURCE`. This allows to edit the projects on the host and conveniently cross compile the projects with Docker!

Windows:

        SET YIO_BUILD_OUTPUT=d:/projects/yio

Linux & macOS:

        export YIO_BUILD_OUTPUT=/projects/yio

Note: bind mounting the project folder from the host will have a negative build performance impact on macOS and Windows.

#### Script Usage

    yio <build-command>

*build-command*:

    info     Print Git information of the available projects
    init     Initialize build: checkout all projects & prepare buildroot
    bash     Start a shell for manual operations inside the container
             The yio script also works inside the container
    clean    Clean all projects
    build    Build all projects
    rebuild  Clean and then build all projects
    update   Update all projects on the current branch
    git [options] <command> [<args>] Perform Git command on all projects

    <project> git [options] <command> [<args>]
                      Perform Git command on given project
    <project> clean   Clean the given project
    <project> build   Build the given project

See the available projects with the `info` command.

#### Examples

Build all:

    yio build

Switch Git branch of remote-software project to a feature branch:

    yio remote-software git checkout feature/foobar

See Git status of remote-os project:

    yio remote-os git status

Clean remote-os project:

    yio remote-os clean

Pull latest sources in the current branches:

    yio update

### b) Regular Docker

#### Create Volumes

To use the buildroot ccache and to only build changed artefacts in consecutive builds the build output needs to be persisted. Following volume mount points are defined:

- `/yio-remote/target`: Built artefacts, intended for bind mounting to host.

  Initially empty. After a successful build the final artefact(s) will be copied into here.

- `/yio-remote/src`: Cloned Git repositories, intended for a named Docker volume.

  Will be initialized with the cloned Git repositories with the `init` command.

- `/yio-remote/buildroot`: Buildroot downloads and ccache, intended for a named Docker volume.

  Will be initialized with the downloaded package sources from within the image during the (initial) build.

Create Docker Volumes:

    docker volume create yio-projects
    docker volume create yio-buildroot

#### Manual command

    docker run --rm -it \
        -v ./build-output:/yio-remote/target \
        -v yio-projects:/yio-remote/src \
        -v yio-buildroot:/yio-remote/buildroot \
        gcr.io/yio-remote/build \
        <build-command>

See wrapper scripts above for `build-command` description.

### c) Docker Compose

An example [Docker Compose](https://docs.docker.com/compose/) file has been provided with the following features:

- [Docker Volumes](https://docs.docker.com/storage/volumes/) for:
  - yio-projects: holds all project sources
  - yio-buildroot: Buildroot package sources and ccache
- [Bind mounts](https://docs.docker.com/storage/bind-mounts/) the host directory `./build-output` to transfer the final build artefacts.
- Executes a full build when started

Usage:

    docker-compose up

### Clean Up

Clean Buildroot:

    yio remote-os clean

Remove Buildroot ccache, downloaded package sources and intermediate build interfacts:

    docker volume rm yio-buildroot

Remove Docker volume containing project sources:

    docker volume rm yio-projects

## Creating the YIO-Remote Build Image

The Docker image can be built with the Dockerfile in the subdirectory `./yio-image`:

- Based on Ubuntu 19.10
- Build takes several minutes depending on internet speed and mirrors used

The wrapper script `./yio-image/build.sh` handles build parameters (e.g. disabling build cache) and optionally pushes the image into a registry. See options with:

    ./build.sh -h

Automatic build for macOS and Linux:

    ./build.sh

Manual build command:

    docker build --pull -t gcr.io/yio-remote/build -f Dockerfile .

### Environment Variables

The following environment variables are safe to change:

- `TZ`: time zone. Default: `Europe/Zurich`

All other variables should _not_ be changed without understanding the implication.

### Optional Build Arguments

- `UBUNTU_MIRROR`: specifies the Ubuntu mirror. Set it to a mirror close to you. Default: `http://mirror.init7.net`
- `YIO_REMOTE_UID`: User ID of the Linux user. Useful to match your host user in bind mounts. Default: `1000`
- `YIO_REMOTE_GID`: Group ID of the Linux user. Default: `1000`
