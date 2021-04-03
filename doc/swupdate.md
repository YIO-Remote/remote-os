# Over The Air (OTA) Updates

[SWUpdate](https://sbabic.github.io/swupdate/index.html) is used for providing OTA updates.

## SWUpdate Configuration

- Build configuration: [swupdate.config](../buildroot-external/board/remote/swupdate.config)
- Runtime configuration: [/etc/swupdate.cfg](../buildroot-external/board/remote/rootfs-overlay/etc/swupdate.cfg)
  - [Configuration documentation](https://github.com/sbabic/swupdate/blob/master/examples/configuration/swupdate.cfg)

## SWUpdate Tools

The following client tools are included:

- [Mongoose web server](https://sbabic.github.io/swupdate/mongoose.html)
- [swupdate-client](https://sbabic.github.io/swupdate/swupdate-client.html)
- [swupdate-progress](https://sbabic.github.io/swupdate/swupdate-progress.html)
- [swupdate-sysrestart](https://sbabic.github.io/swupdate/swupdate-sysrestart.html)
- [swupdate-hawkbitcfg](https://sbabic.github.io/swupdate/swupdate-hawkbitcfg.html)
- [swupdate-sendtohawkbit](https://sbabic.github.io/swupdate/swupdate-sendtohawkbit.html)

## U-Boot Integration

### U-Boot Environment

|        Key        | Value |             Description             |
|-------------------|-------|-------------------------------------|
| bootcount         | 0..n  | U-Boot feature                      |
| bootlimit         | 3     | "                                   |
| altbootcmd        |       | "                                   |
| upgrade_available | 1     | "                                   |
| boot_system       | A,B   | Specifies the active system to boot |

### Boot Script

The U-Boot boot script [uboot-boot.ush](https://github.com/YIO-Remote/remote-os/blob/master/buildroot-external/board/remote/uboot-boot.ush) reads the environment variables and loads either system A or B.

Failed boot handling with bootcount > bootlimit is handled by U-Boot itself. If the bootlimit is reached, the `altbootcmd` is executed, which swaps the value in `boot_system`.

## Linux Integration

### Good Boot Verification

After a system update the boot up is monitored to determine if the update suceeded. The good boot is confirmed by the [/usr/libexec/reset-bootcount.sh](../buildroot-external/rootfs-overlay/usr/libexec/reset-bootcount.sh) script and triggered by systemd [app-update-bootcount.service](../buildroot-external/rootfs-overlay/etc/systemd/system/app-update-bootcount.service) and [app-update-bootcount.timer](../buildroot-external/rootfs-overlay/etc/systemd/system/app-update-bootcount.timer):

- The good boot verification is only active if `upgrade_available=1` is set.
- If the app is still running 3 minutes after boot up, then this is considered a succesful update.
- The systemd [app.service](../buildroot-external/rootfs-overlay/etc/systemd/system/app.service) has a watchdog configured, which reboots the system if the app is restarted more than twice within a minute.
