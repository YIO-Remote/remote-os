# Remove /var from rootfs because it will be in its own partition
GENIMAGE_TMP="${BUILD_DIR}/genimage.tmp"
mkdir -p "${GENIMAGE_TMP}"
set -ev
rm -rf "${GENIMAGE_TMP}/var"
mv "${TARGET_DIR}/var" "${GENIMAGE_TMP}/"
mkdir -p "${TARGET_DIR}/var"

# Add mount points
mkdir -p "${TARGET_DIR}/boot"
mkdir -p "${TARGET_DIR}/home"
mkdir -p "${TARGET_DIR}/etc/wpa_supplicant"
