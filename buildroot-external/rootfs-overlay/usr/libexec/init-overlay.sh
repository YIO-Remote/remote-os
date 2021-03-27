#!/bin/sh

echo "Mounting persistent data volume"
/bin/mount /mnt/data

echo "Preparing persistent /var overlay"
/bin/mkdir -p /mnt/data/ov/var /mnt/data/ov/var-work

echo "Created upper and work dirs for /var overlay"

# first run initialization for bind mounts in /etc/fstab
if [ ! -r /mnt/data/ov/var/etc/hostname ]; then
    echo "First run: provisioning /var overlay data..."
    /bin/mkdir -p /mnt/data/ov/var/etc/wpa_supplicant
    /bin/cp -f /etc/hostname /mnt/data/ov/var/etc/
    /bin/cp -f /etc/hosts /mnt/data/ov/var/etc/
    # Signal first boot to systemd: https://www.freedesktop.org/software/systemd/man/machine-id.html
    /bin/echo "uninitialized" > /mnt/data/ov/var/etc/machine-id
fi

/bin/mount overlay -t overlay /var -olowerdir=/var,upperdir=/mnt/data/ov/var,workdir=/mnt/data/ov/var-work
echo "Mounted /var overlay"

# Temporary testing: create /etc overlay to figure out all services which write into it! Lost after reboot!
# TODO systemd update marker file in /etc https://www.freedesktop.org/software/systemd/man/systemd-update-done.service.html
echo "Preparing in-memory /etc overlay"
/bin/mkdir -p /mnt/data/ov/.tmpfs
/bin/mount -t tmpfs tmpfs /mnt/data/ov/.tmpfs -o mode=0700
echo "Created tmpfs /mnt/data/ov/.tmpfs"
/bin/mkdir /mnt/data/ov/.tmpfs/etc /mnt/data/ov/.tmpfs/etc-work
echo "Created upper and work dirs for /etc overlay"

/bin/mount overlay -t overlay /etc -olowerdir=/etc,upperdir=/mnt/data/ov/.tmpfs/etc,workdir=/mnt/data/ov/.tmpfs/etc-work
echo "Mounted /etc overlay"

# Handling /etc/machine-id on a read only root ain't easy with systemd.
# This hack kinda works, even though there's still an error during boot when systemd tries to commit the machine-id,
# but it is still written to disk and used during consecutive boots.
/bin/mount -o bind /var/etc/machine-id /etc/machine-id

exec /sbin/init
