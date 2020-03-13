# home directory is not freely changeable!
# systemd services don't support env variables in ExecStart!
export YIO_HOME=/opt/yio
# remote-os release, set during build
export YIO_OS_VERSION=$BUILD_VERSION
# Git hash of the remote-os repo, set during build
export YIO_OS_GITHASH=$GIT_HASH
export YIO_LOG_DIR=/var/log
export YIO_LOG_DIR_UPDATE=/boot/log
