# YIO remote-os

<https://www.yio-remote.com/> | <https://github.com/YIO-Remote>

- Version: $BUILD_VERSION
- Build date: $BUILD_DATE

## Boot Options

### WiFi Configuration

To use a pre-defined `wpa_supplicant.conf` for your WIFI network, put this file in the root of this boot partition.  
This is required if you have a network using WEP or EAP, which are not supported in the remote-software WIFI configuration.

You can use the `wpa_supplicant.conf.template` as a starting point. For further information, please see:

- <https://www.raspberrypi.org/documentation/configuration/wireless/headless.md>
- <https://w1.fi/cgit/hostap/plain/wpa_supplicant/wpa_supplicant.conf>

Attention:

- If a wpa_supplicant.conf file is present in /boot, the initial setup is skipped during first run.
- The Raspberry Pi 0 W doesn't support 5GHz networks!

### Timezone configuration

The system time is automatically set with NTP and the default timezone is UTC.

- To set another timezone create a file named `timezone` in the root of this boot partition.
- Content is a single line containing the Linux TZ name.  
  See <https://en.wikipedia.org/wiki/List_of_tz_database_time_zones> for a list of valid TZ database names.  
  Examples:
  - Europe/Copenhagen
  - Asia/Hong_Kong
  - America/Vancouver

### Bluetooth Serial Console

To enable a Bluetooth serial console, create a marker file `btconsole` in the root of this boot partition.

### Factory Reset

To factory reset the configuration:

1. Reboot remote
2. When the YIO splashscreen appears, immediately press these 3 keys:
   - Volume up
   - Top left outlined circle
   - DPad down
3. The remote will automatically reboot and start the initial setup.
   - If the splashscreen animation starts, then the reset didn't work!
