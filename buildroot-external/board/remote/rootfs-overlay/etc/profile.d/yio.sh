# home directory is not freely changeable!
# systemd services don't support env variables in ExecStart!
export YIO_HOME=/opt/yio
export YIO_APP_DIR=${YIO_HOME}/app
export YIO_PLUGIN_DIR=${YIO_HOME}/app-plugins
export YIO_MEDIA_DIR=${YIO_HOME}/media
export YIO_SCRIPT_DIR=${YIO_HOME}/scripts
export YIO_WEB_CONFIGURATOR_DIR=${YIO_HOME}/web-configurator
# remote-os release, set during build
export YIO_OS_VERSION=$BUILD_VERSION
# Git hash of the remote-os repo, set during build
export YIO_OS_GITHASH=$GIT_HASH
export YIO_LOG_DIR=/var/log
export YIO_LOG_DIR_UPDATE=/boot/log
export YIO_CFG_OVERRIDE_DIR=/boot
