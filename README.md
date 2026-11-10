<p align="center"><img src="logo/berrux-logo.svg" width="300" alt="Berrux"></p>
# Berrux

**Made by Ian, with help from Mischa.**

A lightweight Linux for the Raspberry Pi 5, built with
[Buildroot](https://buildroot.org).

Work in progress. Not affiliated with or endorsed by Raspberry Pi Ltd.

Tux the penguin was created by Larry Ewing. The Berrux penguin is an original
redraw in that style.

## What this is

The tree in this repository is **not** a Debian/Ubuntu/Arch derivative. It is a
[Buildroot](https://buildroot.org) external tree: Buildroot compiles the kernel,
C library, BusyBox and the packages you pick into one image.

This repository is the Berrux *layer*; Buildroot itself is the tool that builds
it. Nothing here is prebuilt, so you build the image on your own machine.

Only the board-specific parts differ between machines. They live in the defconfig
under `configs/`, so the Pi 5 image and the generic QEMU image share the same
overlay and scripts.

## Layout

| Path | Purpose |
|---|---|
| `external.desc`, `external.mk`, `Config.in` | Register this tree with Buildroot |
| `configs/berrux_pi5_defconfig` | Raspberry Pi 5, produces a bootable SD card image |
| `configs/berrux_generic_aarch64_defconfig` | Board-agnostic starting point (QEMU) |
| `board/berrux/overlay/` | Files copied into the image (`/etc/motd`, `/etc/berrux-release`) |
| `board/berrux/pi5/` | Pi 5 boot files (`config.txt`, `cmdline.txt`), SD card layout, kernel fragment, post-image script |
| `board/berrux/post-build.sh` | Stamps the image with target, arch and build date |
| `package/Config.in`, `package/*/*.mk` | Berrux's own packages, added here |

## Build the Raspberry Pi 5 image

You need a Linux machine, about 10 GB free, 20–40 minutes, and Buildroot's usual
build dependencies (`build-essential`, `bison`, `flex`, `rsync`, `bc`, `cpio`,
`unzip`, `file`, `wget`, `perl`).

```sh
wget https://buildroot.org/downloads/buildroot-2024.02.11.tar.gz
tar xzf buildroot-2024.02.11.tar.gz
cd buildroot-2024.02.11

export BR2_EXTERNAL=/path/to/Berrux-Os
make berrux_pi5_defconfig
make -j"$(nproc)"
```

That writes `output/images/berrux-pi5.img`: a two-partition SD card image with a
64 MB FAT boot partition (`config.txt`, `cmdline.txt`, the kernel, the Pi 5
device tree) and a 120 MB ext4 root partition.

Put it on a card with Raspberry Pi Imager, or:

```sh
sudo dd if=output/images/berrux-pi5.img of=/dev/sdX bs=4M conv=fsync
```

`/dev/sdX` must be the card, not your disk — `dd` erases all of it.

Then connect a USB-C power supply and watch the serial console at 115200 baud on
the debug UART, or plug in HDMI. Log in as `root` (no password by default), and
`cat /etc/berrux-release` tells you what you built.

### Things that will bite you if you change them

- **The kernel is the Raspberry Pi tree at a pinned commit, with its
  `bcm2712_defconfig`.** A Pi 5's SD card, USB and Ethernet are all behind the
  RP1 southbridge, which mainline 6.1 cannot drive and mainline 6.6 still does
  not drive either. A mainline kernel here boots to a console that cannot mount
  the root filesystem it is sitting next to. Do not "simplify" this back to
  `BR2_LINUX_KERNEL_CUSTOM_VERSION`.
- **The kernel is pinned to a commit**, so rebuilds are reproducible.
- **`bcm2712_defconfig` builds a 16K page kernel**, which not every toolchain can
  link. `board/berrux/pi5/linux-4k-page-size.fragment` switches it to 4K.
- **Everything the defconfig needs is in this repository.** It deliberately does
  not use Buildroot's `board/raspberrypi5/` files: those only exist in Buildroot
  master, so an external tree pointing at them fails on the pinned release.
- **The console is `ttyAMA10`**, the Pi 5's debug UART, not the `ttyAMA0` of
  earlier models.
- **There is no `start.elf` or `fixup.dat` on the boot partition.** A Pi 5 keeps
  its bootloader in EEPROM, so it reads `config.txt` and the kernel directly.
- No device-tree overlays ship in this image yet, so `dtoverlay=` lines in
  `config.txt` will not resolve.

## Try it with no hardware at all

The generic defconfig builds for QEMU's `virt` machine, which runs on any 64-bit
host with `qemu-system-aarch64`. Same steps, different defconfig:

```sh
export BR2_EXTERNAL=/path/to/Berrux-Os
make berrux_generic_aarch64_defconfig
make -j"$(nproc)"
```

Then boot it:

```sh
qemu-system-aarch64 \
	-M virt -cpu cortex-a53 -smp 1 -m 512 \
	-kernel output/images/Image \
	-append "root=/dev/vda rw console=ttyAMA0" \
	-drive file=output/images/rootfs.ext2,if=virtio,format=raw \
	-netdev user,id=net0 -device virtio-net-pci,netdev=net0 \
	-nographic
```

Log in as `root` (no password by default), and `/etc/berrux-release` will tell
you what you built.

## Build it for your own board

Copy `configs/berrux_generic_aarch64_defconfig` and change the hardware parts:

- **ARM board:** set `BR2_LINUX_KERNEL_INTREE_DTS_NAME` (or
  `BR2_LINUX_KERNEL_CUSTOM_DTS_PATH`) to your board's device tree.
- **x86 / UEFI machine:** use `BR2_x86_64=y` and
  `BR2_LINUX_KERNEL_DEFCONFIG="x86_64"`.
- **RISC-V:** `BR2_riscv=y`, `BR2_RISCV_64=y`.
- **Raspberry Pi 5:** use `configs/berrux_pi5_defconfig` as-is instead — the
  kernel changes too, not just the device tree.

The easiest route for a new board is to start from Buildroot's own defconfig for
that board (`make list-defconfigs`) and then add these two lines, which are all
Berrux needs to appear in the image:

```
BR2_ROOTFS_POST_BUILD_SCRIPT="$(BR2_EXTERNAL_BERRUX_PATH)/board/berrux/post-build.sh"
BR2_ROOTFS_OVERLAY="$(BR2_EXTERNAL_BERRUX_PATH)/board/berrux/overlay"
```

Root filesystem choice (ext2/ext4, squashfs, initramfs, UBI, …) is free — the
overlay and post-build script work regardless.

## Adding packages

Create `package/<name>/<name>.mk` and add its `source` line to
`package/Config.in`. `external.mk` picks the makefile up automatically.

## Credits

Ian built Berrux, with Mischa helping out. `cat /etc/berrux-release` in a booted
image says so too.
