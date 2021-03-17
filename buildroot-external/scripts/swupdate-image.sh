#! /bin/echo Please-source

function create_ota_update() {
    local upd_img_name=yio-${BOARD_ID}-v${BUILD_VERSION}.swu

    cp ${BOARD_DIR}/sw-description ${BINARIES_DIR}

    # replace tags in sw-description
    sed -i "s/\$BUILD_VERSION/$BUILD_VERSION/g" ${BINARIES_DIR}/sw-description
    sed -i "s/\$BOARD_ID/$BOARD_ID/g" ${BINARIES_DIR}/sw-description

    pushd ${BINARIES_DIR}
    for f in ${OTA_IMG_FILES} ; do
        echo ${f}
    done | cpio -ovL -H crc > ${upd_img_name}
    popd

    echo "Generating hash for ${upd_img_name} ..."
    shasum -a 256 ${upd_img_name} > ${upd_img_name}.sha256sum
}