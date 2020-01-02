#!/bin/bash
#
# Entrypoint script for YIO remote-os build
#
# Quickly hacked together - WORK IN PROGRESS!
#

set -e

DEBUG_BUILD=y
CPU_CORES=$(getconf _NPROCESSORS_ONLN)

SDCARD_IMG=${BUILDROOT_OUTPUT}/images/yio-remote-sdcard.img
BUILD_OUTPUT=/yio-remote/target

CROSSCOMPILE_BIN=${BUILDROOT_OUTPUT}/host/bin
QMAKE_CROSSCOMPILE=${CROSSCOMPILE_BIN}/qmake

LINGUIST_LUPDATE=/usr/lib/qt5/bin/lupdate
LINGUIST_LRELEASE=/usr/lib/qt5/bin/lrelease

#=============================================================

GitProjects=(
    "https://github.com/YIO-Remote/integration.dock.git,dev"
    "https://github.com/YIO-Remote/integration.homey.git,dev"
    "https://github.com/YIO-Remote/integration.home-assistant.git,dev"
    "https://github.com/YIO-Remote/integration.ir.git,dev"
    "https://github.com/YIO-Remote/integration.openhab.git,dev"
    "https://github.com/YIO-Remote/integration.openweather.git,dev"
    "https://github.com/YIO-Remote/integration.roon.git,develop"
    "https://github.com/YIO-Remote/integration.spotify.git,dev"
    "https://github.com/YIO-Remote/remote-os.git,feature/develop"
    "https://github.com/YIO-Remote/remote-software.git,develop"
    "https://github.com/YIO-Remote/web-configurator.git,master"
)

QtIntegrationProjects=(
    integration.dock
    integration.ir
    integration.home-assistant
    integration.homey
)

#=============================================================

usage() {
  cat << EOF

YIO-remote build image.

Commands:
info     Print Git information of the available projects
init     Initialize build: checkout all projects & prepare buildroot
bash     Start a shell for manual operations inside the container
         The yio script also works inside the container
clean    Clean all projects
build [release]   Build all projects with debug or release settings.
         Initializes projects if required.
rebuild [release] Clean and then build all projects
update   Update all repositories on the current branch (git pull)
git [options] <command> [<args>] Perform Git command on all projects

<project> git [options] <command> [<args>]
                  Perform Git command on given project
<project> clean   Clean the given project
<project> build [release]
                  Build the given project with debug or release settings
qt build [release]
                  Build all Qt projects with debug or release settings

EOF
}

header() {
    echo "--------------------------------------------------------------------------------"
    echo $1
    echo "--------------------------------------------------------------------------------"
}

#=============================================================

gitInfo() {
    cd "${YIO_SRC}/$1"
    if [ -d ".git" ]; then
        printf "%-30s %-30s %s\n" $1 $(git rev-parse --abbrev-ref HEAD) $(git log --pretty=format:'%h' -n 1)
    fi
}

#=============================================================

projectInfo() {
    subdircount=`find "${YIO_SRC}" -maxdepth 1 -type d | wc -l`
    if [ $subdircount -lt 2 ]
    then
        echo "No projects found. Run 'init' first to clone Git projects"
        exit 1
    fi
    echo ""
    echo "Git information:"
    cd "${YIO_SRC}"
    for D in */; do
        gitInfo "$D"
    done
    echo ""
    # TODO print docker build image information
}

#=============================================================

checkoutProject() {
    name="${1##*/}"
    projectName="${name%.*}"

    if [ ! -d "${YIO_SRC}/${projectName}" ]; then
        header "Git clone $1"
        cd "${YIO_SRC}"
        git clone $1
        cd ${projectName}
        git checkout $2
    fi
}

checkoutProjects() {
    for item in ${GitProjects[*]}; do
        PROJECT=$(awk -F, '{print $1}' <<< $item)
        BRANCH=$(awk -F, '{print $2}' <<< $item)
        checkoutProject $PROJECT $BRANCH
    done
}

#=============================================================

executeOnProject() {
    cd "${YIO_SRC}/$1"
    if [ "$1" = "remote-os" ]; then
        cd buildroot
        printf "%-20s: '" $1/buildroot
    else
        printf "%-20s: '" $1
    fi
    echo "${@:2}'"
    ${@:2}
}

#=============================================================

gitCommandAll() {
    subdircount=`find "${YIO_SRC}" -maxdepth 1 -type d | wc -l`
    if [ $subdircount -lt 2 ]
    then
        echo "No projects found. Run 'init' first to clone Git projects"
        return
    fi
    cd "${YIO_SRC}"
    echo ""
    for D in */; do
        if [ -d "${YIO_SRC}/${D}/.git" ]; then
            cd "${YIO_SRC}/${D}"
            printf "%-20s: 'git %s" $D
            echo "$@'" 
            git $@
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

    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

    touch $BUILD_OUTPUT/write-test-$TIMESTAMP || {
        echo "ERROR: Build output directory is not writable: $BUILD_OUTPUT"
        exit 1
    }
    rm $BUILD_OUTPUT/write-test-$TIMESTAMP
}

checkToolchainExists() {
    if [ -z "$BUILDROOT_OUTPUT" ]; then
        echo "Environment variable BUILDROOT_OUTPUT not defined! Value must point to buildroot output folder of the device. Cross compile not possible!"
        exit 1
    fi

    if [ ! -x "$QMAKE_CROSSCOMPILE" ]; then
        echo "ERROR: Toolchain for RPi cross compilation hasn't been built yet! Build remote-os first"
        exit 1
    fi

    if [ ! -f "${YIO_SRC}/remote-os/.toolchain-ready" ]; then
        echo "ERROR: Toolchain is not yet ready! Build remote-os first (control file missing: '${YIO_SRC}/remote-os/.toolchain-ready')"
        exit 1
    fi
}

#=============================================================

cleanRemoteOS() {
    if [ -f "${YIO_SRC}/remote-os/buildroot/Makefile" ]; then
        header "Cleaning remote-os project..."

        cd "${YIO_SRC}/remote-os"
        make clean
    fi
}

initRemoteOS() {
    header "Initializing Buildroot project in remote-os..."

    checkProjectExists remote-os

    cd "${YIO_SRC}/remote-os"
    git submodule init
    git submodule update
}

buildRemoteOS() {
    checkProjectExists remote-os
    checkBuildOutputExists
    initRemoteOS

    cd "${YIO_SRC}/remote-os"
    header "Building remote-os project branch $(git rev-parse --abbrev-ref HEAD) (Git commit: $(git log --pretty=format:'%h' -n 1))"

    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    echo "Build started at: ${TIMESTAMP}" > $BUILD_OUTPUT/buildroot-${TIMESTAMP}.log
    echo "Build command: make $@" >> $BUILD_OUTPUT/buildroot-${TIMESTAMP}.log

    cd "${YIO_SRC}/remote-os"
    set -o pipefail
    make $@ 2>&1 | tee -a $BUILD_OUTPUT/buildroot-${TIMESTAMP}.log
    echo "Build finished at: $(date)" >> $BUILD_OUTPUT/buildroot-${TIMESTAMP}.log
    echo ""

    if [ ! "$1" = "SKIP_BUILD_IMAGE=y" ]; then
        header "remote-os build succeeded: copying SD card image to $BUILD_OUTPUT"
        cp "$SDCARD_IMG" $BUILD_OUTPUT
    fi
}

#=============================================================

cleanQtProject() {
    if [ -f "${YIO_SRC}/${1}/Makefile" ]; then
        header "Cleaning Qt project $1..."
        cd "${YIO_SRC}/$1"
        make clean
    fi
}

buildQtProject() {

    checkToolchainExists

    if [ ! -d "${YIO_SRC}/${1}" ]; then
        echo "WARN: Project $1 doesn't exist"
        return
    fi

    cd "${YIO_SRC}/$1"

    header "Building Qt project $1 branch $(git rev-parse --abbrev-ref HEAD) (Git commit: $(git log --pretty=format:'%h' -n 1))"

    if [ "$1" = "remote-software" ]; then 
        header "Creating translation files..."
        $LINGUIST_LUPDATE remote.pro
        $LINGUIST_LRELEASE remote.pro
    fi

    # do a shadow build to keep project directory clean
    mkdir -p build
    cd build

    $QMAKE_CROSSCOMPILE "${YIO_SRC}/$1" "CONFIG+=$(if [ "$DEBUG_BUILD" = "n" ]; then echo "release"; else echo "debug CONFIG+=qml_debug"; fi)"
    make qmake_all

    make -j$CPU_CORES

    if [ "$1" = "remote-software" ]; then 
        header "Copying remote-software binary and plugins to $BUILD_OUTPUT"
        BUILD_BINARY_DIR="${YIO_SRC}/binaries/linux-gcc-arm/"$(if [ "$DEBUG_BUILD" = "n" ]; then echo "release"; else echo "debug"; fi)
        cp  "${BUILD_BINARY_DIR}/remote" $BUILD_OUTPUT
        cp -r "${BUILD_BINARY_DIR}/plugins" $BUILD_OUTPUT

        # HACK transfer built remote application and plugins to remote-os.
        # Ok for initial test version, but we need to clean up the binary handling in remote-os!
        BUILDROOT_DEST="${YIO_SRC}/remote-os/overlay/usr/bin/yio-remote"
        echo "Copying remote-software binary and plugins to remote-os: $BUILDROOT_DEST"
        header "WARNING: work in progress until there are remote-software & plugin releases!"

        rm -Rf "${BUILDROOT_DEST}"/fonts/*
        rm -Rf "${BUILDROOT_DEST}"/icons/*
        rm -Rf "${BUILDROOT_DEST}"/plugins/*
        rm -Rf "${BUILDROOT_DEST}"/www/config/*

        mkdir -p "${BUILDROOT_DEST}"/fonts
        mkdir -p "${BUILDROOT_DEST}"/icons
        mkdir -p "${BUILDROOT_DEST}"/plugins
        mkdir -p "${BUILDROOT_DEST}"/www/config

        cp "${BUILD_BINARY_DIR}"/config.json "${YIO_SRC}"/remote-os/rpi0/boot/
        cp "${BUILD_BINARY_DIR}"/remote "${BUILDROOT_DEST}"
        chmod 755 "${BUILDROOT_DEST}"/remote
        cp "${BUILD_BINARY_DIR}"/translations.json "${BUILDROOT_DEST}"

        cp -r "${BUILD_BINARY_DIR}"/fonts "${BUILDROOT_DEST}"
        cp -r "${BUILD_BINARY_DIR}"/icons "${BUILDROOT_DEST}"
        cp -r "${BUILD_BINARY_DIR}"/plugins "${BUILDROOT_DEST}"
        cp -r "${YIO_SRC}"/web-configurator/* "${BUILDROOT_DEST}/www/config/"
    fi
}

#=============================================================

initialize() {
    checkoutProjects
    initRemoteOS
}

cleanAllProjects() {
    header "Cleaning all projects..."

    for project in ${QtIntegrationProjects[*]}; do
        cleanQtProject $project
    done

    cleanQtProject remote-software
    #cleanRemoteOS
}

buildAllQtProjects() {
    header "Building all Qt projects..."

    subdircount=`find "${YIO_SRC}" -maxdepth 1 -type d | wc -l`
    if [ $subdircount -lt 2 ]
    then
        echo "No projects found. Initializing build..."
        initialize
    fi

    # buildroot toolchain must be built first to cross compile Qt projects
    if [[ ! -x "$QMAKE_CROSSCOMPILE" || ! -f "${YIO_SRC}/remote-os/.toolchain-ready" ]]; then
        echo "Buildroot toolchain is not yet ready: building remote-os without SD card image..."
        buildRemoteOS SKIP_BUILD_IMAGE=y
    fi

    for project in ${QtIntegrationProjects[*]}; do
        buildQtProject $project
    done

    buildQtProject remote-software
}

buildAllProjects() {
    header "Building all projects..."
    buildAllQtProjects
    buildRemoteOS
}

#=============================================================
# Script starts here
#=============================================================
if [ -z "$YIO_SRC" ]; then 
    echo "Environment variable YIO_SRC not defined! Value must point to root folder of YIO remote project repositories."
    exit 1
fi

if [ $# -eq 1 ] && ([ "$1" = "bash" ] || [ "$1" = "/bin/bash" ]); then
    # manual mode: jump to shell
    exec bash
elif [ $# -eq 1 ]; then
    # handle single command
    if [ "$1" = "help" ] || [ "$1" = "-h" ]; then
        usage
    elif [ "$1" = "info" ]; then
        projectInfo
    elif [ "$1" = "init" ]; then
        initialize
    elif [ "$1" = "clean" ]; then
        cleanAllProjects
    elif [ "$1" = "build" ]; then
        buildAllProjects
    elif [ "$1" = "rebuild" ]; then
        cleanAllProjects
        buildAllProjects
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
elif [ "$1" = "build" ] && [ "$2" = "release" ]; then
    DEBUG_BUILD=n
    buildAllProjects
elif [ "$1" = "rebuild" ] && [ "$2" = "release" ]; then
    DEBUG_BUILD=n
    cleanAllProjects
    buildAllProjects
elif [ "$1" = "qt" ] && [ "$2" = "build" ]; then
    if [ "$3" = "release" ]; then
        DEBUG_BUILD=n
    fi
    buildAllQtProjects
elif [ "$1" = "buildroot" ]; then
    cd "${YIO_SRC}/remote-os/buildroot"
    make ${@:2}
elif [ "$1" = "git" ]; then
    gitCommandAll ${@:2}
elif [ "$2" = "git" ] && (( $# > 2 )); then
    checkProjectExists $1
    cd "${YIO_SRC}/${1}"
    ${@:2}
elif [ "$2" = "clean" ]; then
    checkProjectExists $1
    if [ "$1" = "remote-os" ]; then
        cleanRemoteOS
    else
        cleanQtProject $1
    fi
elif [ "$2" = "build" ]; then
    if [ "$3" = "release" ]; then
        DEBUG_BUILD=n
    fi
    checkProjectExists $1
    cd "${YIO_SRC}/${1}"
    if [ "$1" = "remote-os" ]; then
        buildRemoteOS
    else
        buildQtProject $1
    fi
else
    usage;
    echo "No command given, exiting!"
    exit 1
fi
