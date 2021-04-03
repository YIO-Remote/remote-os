# Developer Documentation

See [Wiki developer documentation](https://github.com/YIO-Remote/documentation/wiki/development) for further information.

To customize remote-os it's highly recommended having experience with:

- [Buildroot](https://buildroot.org/downloads/manual/manual.html)
- Linux operating system
- Building and customizing Linux kernel
- Embedded systems
- Shell scripting
- [Kconfig](https://www.kernel.org/doc/Documentation/kbuild/kconfig-language.txt) for writing Buildroot custom packages

## Project Structure

The following tables give a short overview of the project structure. It is using the Buildroot's _br2-external_ mechanism and was inspired by the [Home Assistant Operating System project](https://github.com/home-assistant/operating-system).

See [Buildroot documentation "Keeping customizations outside of Buildroot"](hhttps://buildroot.org/downloads/manual/manual.html#outside-br-custom) for further information.

### Main Structure

| Directory            | Description                                   |
|----------------------|-----------------------------------------------|
| `buildroot`          | Buildroot snapshot                            |
| `buildroot-external` | Externalized remote-os configuration          |
| `buildroot-patches`  | Patches for Buildroot itself                  |
| `scripts`            | Helper scripts for updating Buildroot and firmware / kernel packages |

### Remote-OS Configuration

All board specific configuration is found under the [`buildroot-external`](buildroot-external) directory:

| Directory            | Description                                   |
|----------------------|-----------------------------------------------|
| `board`              | Target board resources                        |
| `configs`            | Buildroot board configuration                 |
| `kernel`             | Linux kernel configuration fragments          |
| `package`            | Custom Buildroot packages                     |
| `patches`            | Patches for Buildroot packages                |
| `rootfs-overlay`     | Common file system overlay files              |
| `scripts`            | Build hook scripts                            |

## Further Content

- [Partition layout](partition.md)
- [System update with SWUpdate](swupdate.md)
- [Building remote-os](build.md)
- [Technology research](Technology_research.md)
