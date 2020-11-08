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
    local BOOT_OVERLAY="${BOARD_DIR}/boot-overlay"
    local BOOT_DATA="${BINARIES_DIR}/boot"

    mkdir -p ${BOOT_DATA}

    # gather files for boot partition
    cp -r "${BOOT_OVERLAY}"/* "${BOOT_DATA}/"
    cp "${TARGET_DIR}/opt/yio/app/config.json.def" "${BOOT_DATA}/config.json"

    cp "${BINARIES_DIR}"/*.dtb "${BOOT_DATA}/"

    cp -t "${BOOT_DATA}" \
        "${BINARIES_DIR}/rpi-firmware/fixup.dat" \
        "${BINARIES_DIR}/rpi-firmware/start.elf" \
        "${BINARIES_DIR}/rpi-firmware/bootcode.bin"

    # move README file for /scrips/post-image.sh to patch common placeholders
    mv "${BOOT_DATA}/README.md" "${BINARIES_DIR}/"

    cp "${BINARIES_DIR}"/kernel.img "${BOOT_DATA}/"
}

function yios_post_image() {
    echo "No post-image action"
}
