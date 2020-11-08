#!/bin/false
#------------------------------------------------------------------------------
# Common helper functions
#
# Copyright (C) 2020 Markus Zehnder <business@markuszehnder.ch>
#
# This file is part of the YIO-Remote software project.
#------------------------------------------------------------------------------

# Exit on all command errors '-e' while still calling error trap '-E'
# See https://stackoverflow.com/a/35800451
set -eE
trap 'errorTrap ${?} ${LINENO}' ERR

errorTrap() {
  log "ERROR $1 occured in $0 on line $2"

  if [[ -d $TMPDIR ]]; then
    rm -rf $TMPDIR
  fi
}

log() {
  echo "$*"
  if [[ ! -z $LOGFILE ]]; then

    echo `date +%FT%T%Z` "$*" >> "$LOGFILE"
  fi
}

assertEnvVariable() {
  if [[ -z $2 ]]; then
    echo "$1 environment variable not set!"
    exit 1
  fi
}

assertInstalled() {
  command -v $1 >/dev/null 2>&1 || { 
    echo >&2 "Program $1 not installed. Aborting.";
    exit 1;
  }
}

# Retrieve the latest release version from GitHub for the given repository.
# Parameters:
# $1: YIO GitHub repository. E.g. web-configurator, remote-software, etc.
# Output variables:
# - LATEST_RELEASE: release version. E.g. v0.1.2
getLatestRelease() {
    local response=$(curl -s "https://api.github.com/repos/YIO-Remote/${1}/releases/latest")
    LATEST_RELEASE=$(echo -e "$response" | awk -F '"' '/tag_name/{print $4}')
    if [[ -z $LATEST_RELEASE ]]; then
        log "Error getting latest $1 release from GitHub: $response"
        exit 1
    fi
}

# Download the given release from the GitHub repository.
# Parameters:
# $1: YIO GitHub repository. E.g. web-configurator, remote-software, etc.
# $2: Version number. E.g. "v0.1.2"
# $3: Download directory. E.g. "/tmp"
# Output variables:
# - LATEST_RELEASE: release version. E.g. v0.1.2
# - RELEASE_FILE: downloaded file name without path.
downloadRelease() {
    if [[ $1 == web-configurator ]]; then
      RELEASE_FILE="YIO-${1}-${2}.zip"
    else
      if [[ -z $QT_VERSION ]]; then
        log "WARN: Env variable QT_VERSION not defined"
        OS_ARCH="RPI0-release"
      else
        OS_ARCH="RPI0-Qt$QT_VERSION"
      fi
      RELEASE_FILE="YIO-${1}-${2}-${OS_ARCH}.tar"
    fi
    log "Downloading ${1} GitHub release $2 to: ${3}/${RELEASE_FILE}"
    curl -L --fail -o ${3}/${RELEASE_FILE} https://github.com/YIO-Remote/${1}/releases/download/${2}/${RELEASE_FILE}
}

# Download the latest release from the GitHub repository.
# Parameters:
# $1: YIO GitHub repository. E.g. web-configurator, remote-software, etc.
# $2: Download directory. E.g. "/tmp"
# Output variables:
# - LATEST_RELEASE: release version. E.g. v0.1.2
downloadLatestRelease() {
    getLatestRelease $1
    downloadRelease $1 $LATEST_RELEASE $2
}

# Check installed component version against provided version.
# Exits with return code 1 if the versions matches.
# Parameters:
# $1: YIO component installation directory with version.txt 
# $2: Version number to compare against. E.g. "v0.1.2"
# $3: Force flag (boolean) to ignore matching versions
checkVersion() {
    if [[ ! -f ${1}/version.txt ]]; then
        return
    fi

    local INSTALLED_VERSION=$(< ${1}/version.txt)

    if [[ $2 == $INSTALLED_VERSION ]]; then
        if [[ $3 = true ]]; then
            log "Forcing re-installation of version $INSTALLED_VERSION."
            return
        fi

        log "Installed version $INSTALLED_VERSION is up-to-date. Use -f switch to force re-installing it."
        exit 1
    fi
}

# Display confirmation message and wait for user input to confirm
# Parameters:
# $1: Optional message, otherwise "Are you sure?" will be used
# Return: true or false
confirm() {
    read -r -p "${1:-Are you sure? [y/N]} " response
    case "$response" in
        [yY][eE][sS]|[yY]) 
            true
            ;;
        *)
            false
            ;;
    esac
}

ensureScreenIsOn() {
  # TODO improve sledge hammer approach
  # FIXME this doesn't fully work if screen is put in standby from the YIO app.
  #       It's not waking up instantly but much later when the update is almost finished!?

  # make sure the screen and backlight are on, otherwise we'll end up with a dark screen!
  ${YIO_HOME}/scripts/display-init

  if [[ -f $1 ]]; then
      fbv -d 1 "$1"
  fi

  gpio -g mode 12 pwm
  gpio pwm-ms
  gpio pwmc 1000
  gpio pwmr 100
  gpio -g pwm 12 100
}
