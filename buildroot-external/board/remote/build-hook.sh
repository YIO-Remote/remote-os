#! /bin/echo Please-source
#
# Board specific build hook script called from post-build & post-image

function yios_post_build() {
    # Add a console on tty1
    if [ -e ${TARGET_DIR}/etc/inittab ]; then
        grep -qE '^tty1::' ${TARGET_DIR}/etc/inittab || \
	    sed -i '/GENERIC_SERIAL/a\
    tty1::respawn:/sbin/getty -L  tty1 0 vt100 # HDMI console' ${TARGET_DIR}/etc/inittab
    fi
}

function yios_pre_image() {
    # gather files for boot partition
    cp ${BOARD_DIR}/boot/*.txt ${BINARIES_DIR}/
    cp ${TARGET_DIR}/opt/yio/app/config.json.def ${BINARIES_DIR}/config.json
    cp ${BOARD_DIR}/boot/*.md ${BINARIES_DIR}/
    cp ${BOARD_DIR}/boot/*.template ${BINARIES_DIR}/

    mkdir -p ${BINARIES_DIR}/overlays
    cp ${BOARD_DIR}/boot/overlays/*.dtbo ${BINARIES_DIR}/overlays/
}

function yios_post_image() {
    echo "No post-image action"
}
