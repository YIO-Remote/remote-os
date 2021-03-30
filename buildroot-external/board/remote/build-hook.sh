#! /bin/echo Please-source
#
# Board specific build hook script called from post-build & post-image

function yios_post_build() {
    local BOOT_OVERLAY="${BOARD_DIR}/boot-overlay"

    # Add a console on tty1
    if [ -e ${TARGET_DIR}/etc/inittab ]; then
        grep -qE '^tty1::' ${TARGET_DIR}/etc/inittab || \
	    sed -i '/GENERIC_SERIAL/a\
    tty1::respawn:/sbin/getty -L  tty1 0 vt100 # HDMI console' ${TARGET_DIR}/etc/inittab
    fi

    cp "${BINARIES_DIR}/zImage" "${TARGET_DIR}/"
    cp "${BOOT_OVERLAY}/README.md" "${BINARIES_DIR}/"

    # --- Changes for read-only rootfs ---

    # Add mount points
    mkdir -p "${TARGET_DIR}/boot"
    mkdir -p "${TARGET_DIR}/mnt/data"

    # bind mounts
    mkdir -p "${TARGET_DIR}/etc/wpa_supplicant"

    # additional directories
    # - due to log error: bluetoothd[135]: Unable to open adapter storage directory: /var/lib/bluetooth/<MAC:ADDR>
    mkdir -p "${TARGET_DIR}/var/lib/bluetooth"
    mkdir -p "${TARGET_DIR}/var/lib/dropbear"

    # Relocate dropbear's key storage from /etc/dropbear to /var/lib/dropbear
    # See also: ../overlay/etc/systemd/system/dropbear.service.d/create-host-key-directory.conf
    rm -f ${TARGET_DIR}/etc/dropbear
    ln -s /var/lib/dropbear ${TARGET_DIR}/etc/dropbear

    # --- End read-only rootfs ---
}

function yios_pre_image() {
    local BOOT_OVERLAY="${BOARD_DIR}/boot-overlay"
    local BOOT_DATA="${BINARIES_DIR}/boot"

    # patch README file (other fields are patched in /scrips/post-image.sh)
    sed -i "s/\$BOARD_NAME/$BOARD_NAME/g" "${BINARIES_DIR}/README.md"

    mkdir -p ${BOOT_DATA}

    # gather files for boot partition
    cp -r "${BOOT_OVERLAY}"/* "${BOOT_DATA}/"
    cp "${BINARIES_DIR}/README.md" "${BOOT_DATA}/"
    cp "${TARGET_DIR}/opt/yio/app/config.json.def" "${BOOT_DATA}/config.json"

    cp "${BINARIES_DIR}"/*.dtb "${BOOT_DATA}/"

    cp -t "${BOOT_DATA}" \
        "${BINARIES_DIR}/rpi-firmware/fixup.dat" \
        "${BINARIES_DIR}/rpi-firmware/start.elf" \
        "${BINARIES_DIR}/rpi-firmware/bootcode.bin"

    # Partitions
    local genimage_tmp="${BUILD_DIR}/genimage.tmp"

    echo "Creating boot partition..."
    # Everything in ${BOOT_DATA} will end up in the boot partition
    cp "${BINARIES_DIR}/u-boot.bin" "${BOOT_DATA}/"
    cp "${BINARIES_DIR}/boot.scr" "${BOOT_DATA}/"
    rm -rf "${genimage_tmp}"
    genimage                           \
        --rootpath "${BINARIES_DIR}"   \
        --tmppath "${genimage_tmp}"    \
        --inputpath "${BINARIES_DIR}"  \
        --outputpath "${BINARIES_DIR}" \
        --config "${BOARD_DIR}/genimage-boot.cfg"

    echo "Creating recovery partition..."
    rm -rf "${genimage_tmp}"
    rm -rf "${BINARIES_DIR}/recovery"
    mkdir "${BINARIES_DIR}/recovery/"
    # FIXME just a proof of concept. The recovery image needs to hold a bootable Linux and the swupdate image!
    cp "${BINARIES_DIR}/rootfs.squashfs" "${BINARIES_DIR}/recovery/"
    cp "${BINARIES_DIR}/boot.vfat" "${BINARIES_DIR}/recovery/"
    cp "${BINARIES_DIR}/README.md" "${BINARIES_DIR}/recovery/"

    genimage                           \
        --rootpath "${BINARIES_DIR}"   \
        --tmppath "${genimage_tmp}"    \
        --inputpath "${BINARIES_DIR}"  \
        --outputpath "${BINARIES_DIR}" \
        --config "${BOARD_DIR}/genimage-recovery.cfg"
}

function yios_post_image() {
    echo "Cleaning up temporary image creation folders"
    rm -rf "${BUILD_DIR}/genimage.tmp"
    rm -rf "${BINARIES_DIR}/recovery"
}
