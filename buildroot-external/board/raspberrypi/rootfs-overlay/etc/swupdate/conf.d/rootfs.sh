# Determine which rootfs to update

# Get active root filesystem device
ROOTFS_DEV=$(findmnt -rno SOURCE "/")
if [ -z "$ROOTFS_DEV" ]; then
    echo "No root device mount found!"
    exit 1
fi

# Use PARTUUID to make sure we get the correct partition.
# A plugged in USB stick with the same partition label would wreck havoc!
ROOTFS1_DEV=$(blkid -o device -t PARTUUID=b831b597-efc4-4132-b88c-c50a2d4589cf)
ROOTFS2_DEV=$(blkid -o device -t PARTUUID=f2f82015-3087-485a-9241-914026bca453)

if [ "$ROOTFS_DEV" = "$ROOTFS1_DEV" ]; then
    SWUPDATE_ARGS="-e rootfs,rootfs-2"
    echo "System update target: $SWUPDATE_ARGS device=$ROOTFS2_DEV"
elif [ "$ROOTFS_DEV" = "$ROOTFS2_DEV" ]; then
    SWUPDATE_ARGS="-e rootfs,rootfs-1"
    echo "System update target: $SWUPDATE_ARGS device=$ROOTFS1_DEV"
else
    echo "Danger, Will Robinson! Got unexpected root filesystem..."
    exit 1
fi
