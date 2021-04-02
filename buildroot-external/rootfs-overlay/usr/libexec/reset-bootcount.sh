#!/bin/sh
#
# SWUpdate boot count reset script

systemctl is-active --quiet app || {
  echo "Remote app not running!"
  exit 1
}

ISUPGRADING=$(fw_printenv upgrade_available | awk -F'=' '{print $2}')
echo "upgrade_available=$ISUPGRADING"
if [ -z "$ISUPGRADING" ]
then
    echo "No system update pending"
else
    echo "System update pending, verifying system..."
    # TODO refactor once there are any common system checks:
    # - call script from systemd right after app start (instead of delayed timer)
    # - get pid of app
    # - perform system checks
    # - wait ~ 3 min
    # - check if app is still running and has same pid (i.e. didn't get auto-restarted)

    # Perform extra checks here.
    # If anything went wrong, reboot again until the bootlimit is reached
    # which triggers a rollback of the RootFs

    # It's all good! Clear upgrade status and mark partition ok.
    fw_setenv upgrade_available
    fw_setenv bootcount 0
    echo "System update successful. Marked current partition OK."
fi
