#! /bin/echo Please-source
#
# Board specific build hook script called from post-build & post-image

function yios_post_build() {
    echo "Patching YIO app start script to use RPi hardware configuration"
    sed -i "s/\${YIO_APP_DIR}\/remote/\${YIO_APP_DIR}\/remote --cfg \"\/boot\/config.json\" --hw-cfg \"\${YIO_HOME}\/hardware-rpi.json\"/g" "${TARGET_DIR}/opt/yio/app-launch.sh"
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

    cp "${BINARIES_DIR}"/kernel.img "${BOOT_DATA}/"
}


function yios_post_image() {
    echo "No post-image action"
}

