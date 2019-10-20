#!/bin/bash
#
# Entrypoint script for YIO remote-os build
#
# Quickly hacked together - WORK IN PROGRESS!
#

set -e

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
SDCARD_IMG=${YIO_SRC}/remote-os/buildroot/output/images/yio-remote-sdcard.img
BUILD_OUTPUT=/yio-remote/target

#=============================================================

usage() {
  cat << EOF

YIO-remote build image.

Commands:
info     Print Git information of the available projects
bash     Start a shell for manual operations inside the container
clean    Clean all projects
clean    Build all projects
update   Update all projects on the current branch

<project> git [options] <command> [<args>]
                  Perform Git command on given project
<project> clean   Clean the given project
<project> build   Build the given project

EOF
}

#=============================================================

gitInfo() {
    cd ${YIO_SRC}/$1
    if [ -d ".git" ]; then
        printf "%-20s %-10s %s\n" $1 $(git rev-parse --abbrev-ref HEAD) $(git log --pretty=format:'%h' -n 1)
    fi
}

#=============================================================

projectInfo() {
    echo ""
    echo "Git information:"
    cd ${YIO_SRC}
    for D in *; do gitInfo $D; done;
    echo ""
    # TODO print docker build image information
}

#=============================================================

gitCommandAll() {
    cd ${YIO_SRC}
    echo ""
    for D in *; do
        cd ${YIO_SRC}/$D
        if [ -d ".git" ]; then
            printf "%-20s: 'git %s'\n" $D $1
            git $1
        fi
    done
}

#=============================================================

checkProjectExists() {
    if [ ! -d "${YIO_SRC}/${1}" ]; then
        echo "ERROR: Project $1 doesn't exist"
        exit 1
    fi
}

checkBuildOutputExists() {
    # the build output directory should be bind-mounted to the host: make sure it's writable before spending 1h+ building!
    if [ ! -d "$BUILD_OUTPUT" ]; then
        echo "ERROR: Build output directory doesn't exist: $BUILD_OUTPUT"
        exit 1
    fi

    touch $BUILD_OUTPUT/write-test-$TIMESTAMP || {
        echo "ERROR: Build output directory is not writable: $BUILD_OUTPUT"
        exit 1
    }
    rm $BUILD_OUTPUT/write-test-$TIMESTAMP
}

#=============================================================

buildRemoteOS() {
    checkProjectExists remote-os
    checkBuildOutputExists

    cd ${YIO_SRC}/remote-os/buildroot
    set -o pipefail
    make $@ 2>&1 | tee $BUILD_OUTPUT/buildlog-${TIMESTAMP}.log
    echo ""
    echo "remote-os build succeeded: copying SD card image to /yio-remote/build"
    cp "$SDCARD_IMG" $BUILD_OUTPUT
}

#=============================================================

if [ $# -eq 1 ] && ([ "$1" = "bash" ] || [ "$1" = "/bin/bash" ]); then
    # manual mode: jump to shell
    exec bash
elif [ $# -eq 1 ]; then
    # handle single command
    if [ "$1" = "info" ]; then
        projectInfo
    elif [ "$1" = "clean" ]; then
        echo "Cleaning remote-os project..."
        cd ${YIO_SRC}/remote-os/buildroot
        make $1
        echo ""
        echo "TODO clean Qt projects!"
    elif [ "$1" = "build" ]; then
        echo "Building remote-os project..."
        buildRemoteOS
        echo ""
        echo "TODO build Qt projects!"
    elif [ "$1" = "wait" ]; then
        # helper command for docker-compose 'debugging'
        cat << EOF

YIO-Remote build container is running.

Use 'docker exec -it <container-name> yio-remote-build.sh <command>' to execute build commands"

EOF
        usage
        bash -c "trap : TERM INT; sleep infinity & wait"
    elif [ "$1" = "update" ]; then
        gitCommandAll pull
    else
        echo "ERROR: Invalid command given, exiting!"
        exit 1
    fi
elif [ "$1" = "buildroot" ]; then
    cd ${YIO_SRC}/remote-os/buildroot
    make ${@:2} 2>&1 | tee $BUILD_OUTPUT/buildlog-${TIMESTAMP}.log
elif [ "$2" = "git" ] && (( $# > 2 )); then
    checkProjectExists $1
    cd ${YIO_SRC}/${1}
    ${@:2}
elif [ "$2" = "clean" ]; then
    checkProjectExists $1
    cd ${YIO_SRC}/${1}
    if [ "$1" = "remote-os" ]; then
        cd buildroot
        make ${@:2}
    else
        echo "ERROR: $2 of project $1 is not yet supported!"
        exit 1
    fi
elif [ "$2" = "build" ]; then
    checkProjectExists $1
    cd ${YIO_SRC}/${1}
    if [ "$1" = "remote-os" ]; then
        buildRemoteOS
    else
        echo "ERROR: $2 of project $1 is not yet supported!"
        exit 1
    fi
else
    usage;
    echo "No command given, exiting!"
    exit 1
fi
