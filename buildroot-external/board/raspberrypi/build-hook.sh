#! /bin/echo Please-source
#
# Board specific build hook script called from post-build & post-image

function yios_post_build() {
    echo "Patching YIO app start script to use RPi hardware configuration"
    sed -i "s/\${YIO_APP_DIR}\/remote/\${YIO_APP_DIR}\/remote --cfg \"\/boot\/config.json\" --hw-cfg \"\${YIO_HOME}\/hardware-rpi.json\"/g" "${TARGET_DIR}/opt/yio/app-launch.sh"

    cp "${BINARIES_DIR}/zImage" "${TARGET_DIR}/"

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
    local BOOT_OVERLAY="${BOARD_DIR}/../boot-overlay"
    local BOOT_DATA="${BINARIES_DIR}/boot"

    # patch README file (other fields are patched in /scrips/post-image.sh)
    cp "${BOOT_OVERLAY}/README.md" "${BINARIES_DIR}/"
    sed -i "s/\$BOARD_NAME/$BOARD_NAME/g" "${BINARIES_DIR}/README.md"

    mkdir -p ${BOOT_DATA}

    # gather files for boot partition
    cp -r "${BOOT_OVERLAY}"/* "${BOOT_DATA}/"
    cp "${BINARIES_DIR}/README.md" "${BOOT_DATA}/"
    cp "${TARGET_DIR}/opt/yio/app/config.json.def" "${BOOT_DATA}/config.json"


    cp "${BINARIES_DIR}"/*.dtb "${BOOT_DATA}/"
    cp -r "${BINARIES_DIR}/rpi-firmware/overlays" "${BOOT_DATA}/"

    # Firmware
    if [[ "${BOARD_ID}" =~ "rpi4" ]]; then
        cp "${BINARIES_DIR}/rpi-firmware/fixup.dat" "${BOOT_DATA}/fixup4.dat" 
        cp "${BINARIES_DIR}/rpi-firmware/start.elf" "${BOOT_DATA}/start4.elf" 
    else
        cp -t "${BOOT_DATA}" \
            "${BINARIES_DIR}/rpi-firmware/fixup.dat" \
            "${BINARIES_DIR}/rpi-firmware/start.elf" \
            "${BINARIES_DIR}/rpi-firmware/bootcode.bin"
    fi

    # Enable 64bit support
    if [[ "${BOARD_ID}" =~ "64" ]]; then
        sed -i "s|#arm_64bit|arm_64bit|g" "${BOOT_DATA}/config.txt"
    fi
}


function yios_post_image() {
    echo "No post-image action"
}

