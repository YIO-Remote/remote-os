# Docker Build Image for YIO-Remote

This Docker image cross compiles all required Qt projects from the YIO-Remote Git repositories and builds the SD card image for the RPi zero.

Image name: `yio-remote/build`

## Concept

Buildroot is easy to use with Linux, not so much with macOS and Windows. Probably possible, but doesn't work out of the box.
Therefore use Docker with an official Ubuntu image to do the hard work.

- The image contains all required build tools for Buildroot in the remote-os project.
- A helper script is included to download and build all YIO-Remote projects
  - Projects are cloned from the GitHub repositories
  - Buildroot in the remote-os project is initialized (Git submodule)
  - Common build commands perform the required operations on the projects
- Cross compiliation of the Qt projects uses the already built toolchain in the remote-os project.
- Docker Volumes are used to persist data for fast builds after the initial slow build
  - YIO-Remote Git projects
  - Downloaded Buildroot source packages (> 900 MB)
  - Compiled Buildroot toolchain (~ TODO GB) and the Buildroot ccache (~ 1.8 GB)

## Requirements

- Docker (tested with 19.03)
- At least 20 GB of free space
- macOS & Windows Docker configuration:
  - Make sure your Docker VM is large enough and has enough space left
  - Associate at least 4 GB RAM. More RAM = better file system caching
  - Associate as many CPU cores as possible for quicker build times
  - File sharing configured to store the build artefacts on the host
- SSD is highly recommended!
- Internet connection:
  - Ubuntu installation packages will be downloaded during the **Docker Image build**.
  - Buildroot source packages will be downloaded during the **remote-os build** in a Docker container.

## Usage

### a) Regular Docker

A full build takes over an hour and requires approximately 15 GB of disk space!

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

#### Start Build

    docker run --rm -it \
        -v ./build-output:/yio-remote/target \
        -v yio-projects:/yio-remote/src \
        -v yio-buildroot:/yio-remote/buildroot \
        yio-remote/build \
        <build-command>

**build-command**:

    info     Print Git information of the available projects
    init     Initialize build: prepare buildroot
    bash     Start a shell for manual operations inside the container
    clean    Clean all projects
    build    Build all projects
    update   Update all projects on the current branch

    <project> git [options] <command> [<args>]
                      Perform Git command on given project
    <project> clean   Clean the given project
    <project> build   Build the given project

See the available projects with the `info` command.

#### Examples

See Git status of remote-os project:

    docker run --rm -it \
        -v ./build-output:/yio-remote/target \
        -v yio-projects:/yio-remote/src \
        -v yio-buildroot:/yio-remote/buildroot \
        yio-remote/build \
        remote-os git status

Clean remote-os project:

    docker run --rm -it \
        -v ./build-output:/yio-remote/target \
        -v yio-projects:/yio-remote/src \
        -v yio-buildroot:/yio-remote/buildroot \
        yio-remote/build \
        remote-os clean

Pull latest sources:

See Git status of remote-os project:

    docker run --rm -it \
        -v ./build-output:/yio-remote/target \
        -v yio-projects:/yio-remote/src \
        -v yio-buildroot:/yio-remote/buildroot \
        yio-remote/build \
        update

### b) Docker Compose

An example [Docker Compose](https://docs.docker.com/compose/) file has been provided with the following features:

- [Docker Volumes](https://docs.docker.com/storage/volumes/) for:
  - yio-projects: holds all project sources
  - yio-buildroot: Buildroot package sources and ccache
- [Bind mounts](https://docs.docker.com/storage/bind-mounts/) the host directory `./build-output` to transfer the final build artefacts.
- Executes a full build when started

Usage:

    docker-compose up

## Creating the YIO-Remote Build Image

The Docker image is not yet available in a public Docker registry and must be built. See subdirectory `./yio-image`:

- Based on Ubuntu 19.10
- Build takes several minutes depending on internet speed and mirrors used

The wrapper script `./yio-image/build.sh` handles build parameters (e.g. disabling build cache) and optionally pushes the image into a registry. See options with:

    ./build.sh -h

Automatic build for macOS and Linux:

    ./build.sh

Manual build command:

    docker build --pull -t yio-remote/build -f Dockerfile .
