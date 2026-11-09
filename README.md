<p align="center"><img src="logo/berrux-logo.svg" width="300" alt="Berrux"></p>
# Berrux

**Made by Ian, with help from Mischa.**

A small Linux you can build for almost any board — a Raspberry Pi, a mini PC,
an ARM or RISC-V board, or plain old QEMU — using
[Buildroot](https://buildroot.org).

Work in progress. Not affiliated with or endorsed by Raspberry Pi Ltd.

Tux the penguin was created by Larry Ewing. The Berrux penguin is an original
redraw in that style.

## What this is

The tree in this repository is **not** a Debian/Ubuntu/Arch derivative. It is a
[Buildroot](https://buildroot.org) external tree: Buildroot compiles the kernel,
C library, BusyBox and the packages you pick into one image. Nothing here is
tied to a single board — the board-specific parts live entirely in the defconfig
under `configs/`.

## Two editions

| Edition | Base | Size | For |
|---|---|---|---|
| **Berrux Micro** — `configs/`, `board/`, `package/` | Buildroot, built from source | ~50 MB | boards, tinkering, no desktop |
| **Berrux desktop** — `debian/` | Debian 13 (trixie) + LXQt | ~3 GB | people who want a working desktop |

The desktop edition exists because Buildroot has no LXQt packages at all, so
LXQt on Buildroot would mean maintaining dozens of recipes forever. It is
derivative work by design and says so. The rest of this README describes
Berrux Micro; see [`debian/README.md`](debian/README.md) for the other one.

This repository is the Berrux *layer*; Buildroot itself is the tool that builds
it. Nothing in it is prebuilt, so you build the image on your own machine.

## Layout

| Path | Purpose |
|---|---|
| `external.desc`, `external.mk`, `Config.in` | Register this tree with Buildroot |
| `configs/berrux_generic_aarch64_defconfig` | Board-agnostic starting point (QEMU) |
| `board/berrux/overlay/` | Files copied into the image (`/etc/motd`, `/etc/berrux-release`) |
| `board/berrux/post-build.sh` | Stamps the image with arch and build date |
| `package/Config.in`, `package/*/*.mk` | Berrux's own packages, added here |
| `debian/` | The Debian + LXQt desktop edition (separate from the tree above) |

## Try it with no hardware at all

This runs on any 64-bit Linux machine. You need Buildroot's usual build
dependencies (`build-essential`, `bison`, `flex`, `rsync`, `bc`, `cpio`,
`unzip`, `file`, `wget`) plus `qemu-system-aarch64`.

```sh
git clone https://buildroot.org/downloads/buildroot-2024.02.11.tar.gz
tar xzf buildroot-2024.02.11.tar.gz
cd buildroot-2024.02.11

# point BR2_EXTERNAL at this repository
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

Log in as `root` (no password by default) and `/etc/berrux-release` will tell
you what you built.

## Build it for your own board

Copy `configs/berrux_generic_aarch64_defconfig` and change the hardware parts:

- **ARM board:** set `BR2_LINUX_KERNEL_INTREE_DTS_NAME` (or
  `BR2_LINUX_KERNEL_CUSTOM_DTS_PATH`) to your board's device tree.
- **x86 / UEFI machine:** use `BR2_x86_64=y` and
  `BR2_LINUX_KERNEL_DEFCONFIG="x86_64"`.
- **RISC-V:** `BR2_riscv=y`, `BR2_RISCV_64=y`.
- **Raspberry Pi 5 specifically:** the kernel must be 6.6 or newer, so bump
  `BR2_LINUX_KERNEL_CUSTOM_VERSION_VALUE` and use
  `BR2_LINUX_KERNEL_INTREE_DTS_NAME="broadcom/bcm2712-rpi-5-b"`.

The easiest route for a new board is to start from Buildroot's own defconfig
for that board (`make list-defconfigs`) and then add these two lines, which are
all Berrux needs to appear in the image:

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
