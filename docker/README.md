# Docker Build Image for YIO-Remote

This Docker image builds the SD card for the YIO-remote from the remote-os Git repository.

Image name: `yio-remote/build`

## Requirements

- Docker obviously
- At least 20 GB of free space
  - macOS & Windows: make sure your Docker VM is large enough
- macOS & Windows Docker configuration:
  - At least 4 GB RAM. More RAM = better file system caching
  - As many CPU cores as possible for quicker build times
  - File sharing configured to store the build artefacts on the host
- SSD is highly recommended!
- Internet connection:
  - ~ 1.5 GB of packages will be downloaded during the **Docker Image build**.
  - Some packages might still be downloaded during the **remote-os build** with this Docker image.

## Usage

### a) Regular Docker

A full build takes over an hour and requires approximately 15 GB of disk space!

#### Create Volumes

To use the buildroot ccache and to only build changed artefacts in consecutive builds the build output needs to be persisted. Following volume mount points are defined:

- `/yio-remote/target`: Built artefacts, intended for bind mounting to host.

  Initially empty. After a successful build the final artefact(s) will be copied into here.

- `/yio-remote/src`: Cloned Git repositories, intended for a named Docker volume.

  Will be initialized with the cloned Git repositories from within the image.

- `/yio-remote/buildroot`: Buildroot downloads and ccache, intended for a named Docker volume.

  Will be initialized with the downloaded package sources from within the image.

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
    bash     Start a shell for manual operations inside the container
    clean    Clean all projects
    build    Build all projects
    update   Update all projects on the current branch

    <project> git [options] <command> [<args>]
                    Perform Git command on given project
    <project> clean   Clean the given project
    <project> build   Build the given project

Available projects are: `remote-os` - the other projects will follow...

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
- [Bind mounts](https://docs.docker.com/storage/bind-mounts/) the host directory `./build-output` to transfer the built artefacts.
- Executes a full build when started

Usage:

    docker-compose up

## Creating the YIO-Remote Build Image

The Docker image is not yet available in a public Docker registry and must be built. See subdirectory `./image-build`:

- Based on Ubuntu 18.04
- Clones the following YIO-remote repositories in `/yio-remote/src`
  - remote-os
  - remote-software
  - web-configurator
  - *TODO: integrations*
- Initializes the buildroot Git submodule in remote-os/buildroot
- Downloads the buildroot package sources in `/yio-remote/buildroot/dl`
- Downloads about 1.5 GB with the buildroot packages
- Build takes several minutes depending on internet speed and mirrors used

The wrapper script `./image-build/build.sh` handles build parameters (e.g. disabling build cache) and optionally pushing the image into a registry. See options with:

    ./build.sh -h

Automatic build for macOS and Linux:

    ./build.sh

Manual build:

    docker build --pull --no-cache=true -t yio-remote/build -f Dockerfile .
