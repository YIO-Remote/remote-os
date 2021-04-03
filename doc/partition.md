# Partition Layout

The Raspberry Pi boards require a FAT partition to boot from.  
To avoid an extended partition setup with MBR, we are using a hybrid MBR GPT partition table.

| Partition | Size |   Format   |               PARTUUID               |
|-----------|------|------------|--------------------------------------|
| Boot      | 32M  | vfat       | 53a3720d-07aa-4680-ab6d-f2ed0979c9ea |
| Recovery  | 384M | ext4 (TBD) | b9ea076c-315f-422b-85d7-887854415b1e |
| System A  | 512M | SquashFS   | b831b597-efc4-4132-b88c-c50a2d4589cf |
| System B  | 512M | SquashFS   | f2f82015-3087-485a-9241-914026bca453 |
| Data      | 128M | ext4       | 79055324-d7a8-4768-afc6-c7dbfc9a4612 |

- PARTUUIDs are used whenever possible, otherwise file system UUIDs.  
  This guarantees that the correct partition is referenced and allows greater flexibility to change the partition setup.
- Partition indexes are only used in the U-Boot boot script to load the kernel from the active system.

## Boot Partition

The boot partition holds the required firmware files to boot a Raspberry Pi:

- 2nd stage bootloader `bootcode.bin` read by the GPU to enable SDRAM.
- GPU firmware `start.elf`
- `start.elf` reads `config.txt`, `cmdline.txt` and starts the configured `kernel` in config.txt

Instead of directly loading a Linux kernel, we are using U-Boot to determine which system needs to be started. See [SWUpdate](swupdate.md) for more information.

U-Boot consists of:

- `u-boot.bin`: the binary, configured in config.txt
- `boot.scr`: the boot script which determines the active system to load
- `uboot.env`: the persisted U-Boot environment which also holds the boot count and active system

## Recovery Partition

_Work in progress: will contain a factory reset functionality to restore the system._

## System A & B Partitions

Compressed read-only root file systems using [SquashFS](https://en.wikipedia.org/wiki/SquashFS).

## Data Partition

This is a writable ext4 partition to persist configuration data and YIO component updates:

- specific configuration file bind-mounts in `/etc`
- `/var` [OverlayFS](https://en.wikipedia.org/wiki/OverlayFS) data
- `/opt/yio` [OverlayFS](https://en.wikipedia.org/wiki/OverlayFS) data

The OverlayFS file systems are setup in a custom init script.  
This is mainly a quick fix to get everything working with systemd. Setting up all overlays and bind-mounts with systemd might be introduced later, to allow proper file system checks and auto-expansion of the data partition.
