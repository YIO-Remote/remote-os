#! /bin/echo Please-source
#
# SD card image creation
# Called from post-image script

create_disk_image() {
    local sdcard_img_name
    local genimage_tmp="${BUILD_DIR}/genimage.tmp"

    # create SD card image
    rm -rf "${genimage_tmp}"

    genimage                           \
        --rootpath "${TARGET_DIR}"     \
        --tmppath "${genimage_tmp}"    \
        --inputpath "${BINARIES_DIR}"  \
        --outputpath "${BINARIES_DIR}" \
        --config "${YIOS_GENIMAGE_CFG}"

    cd ${BINARIES_DIR}

    sdcard_img_name=yio-${BOARD_ID}-sdcard-v${BUILD_VERSION}
    mv yio-sdcard.img ${sdcard_img_name}.img

    # TODO use xz instead of gz once SWUpdate supports it
    echo "Compressing rootfs.ext4 for update image..."
    rm -f rootfs.ext4
    mv rootfs.ext2 rootfs.ext4
    rm -f rootfs.ext4.gz
    gzip --best rootfs.ext4

    echo "Generating hash for ${sdcard_img_name}.img ..."
    shasum -a 256 ${sdcard_img_name}.img > ${sdcard_img_name}.img.sha256sum

    echo "Zipping SD card image ..."
    rm -f ${sdcard_img_name}.zip
    # TODO include release notes
    zip -j ${sdcard_img_name}.zip ${sdcard_img_name}.img ${sdcard_img_name}.img.sha256sum README.md
}