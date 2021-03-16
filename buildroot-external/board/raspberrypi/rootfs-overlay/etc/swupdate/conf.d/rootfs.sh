# determine which rootfs to update
ROOTFS=$(findmnt -rno SOURCE "/")
if [[ $ROOTFS == "/dev/mmcblk0p2" ]]; then
    SWUPDATE_ARGS="-e rootfs,rootfs-2"
elif [[ $ROOTFS == "/dev/mmcblk0p3" ]]; then
    SWUPDATE_ARGS="-e rootfs,rootfs-1"
else
    echo "Danger, Will Robinson! Got unexpected root filesystem..."
    exit 1
fi
