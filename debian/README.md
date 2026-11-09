# Berrux — desktop edition

This directory builds the **desktop** Berrux: Debian 13 (`trixie`) with LXQt,
as a bootable live ISO.

The Buildroot tree in the repository root is unchanged and separate — it builds
**Berrux Micro**, a tiny console image. Two editions, two bases, on purpose:
Buildroot has no LXQt packages at all (checked against the 2024.02 package
list — no `lxqt` directory exists), so LXQt means Debian.

## What's in the image

- LXQt 2.1 desktop, from Debian's own `live-task-lxqt` set plus the `lxqt`
  metapackage. Nothing hand-built, everything `apt`-installable later.
- Firefox, NetworkManager with its tray applet, and firmware for common Wi-Fi
  and Bluetooth chips.
- Berrux branding: `/etc/berrux-release`, `/etc/issue`, `/etc/motd`, and a
  `berrux-info` command plus a "Welcome to Berrux" menu entry.
- The credit line — Ian, with help from Mischa — in all three of those files.

## Build it

On an arm64 machine (or inside one), as root:

```sh
sudo apt install live-build
sudo ./build.sh
```

Output lands here as `berrux-YYYYMMDD-arm64.iso`.

For a quick demo build on an x86 machine, the same scaffold builds amd64 — it
boots in QEMU or VirtualBox, which is the fastest way to show someone:

```sh
sudo BERRUX_ARCH=amd64 ./build.sh
```

### Cross-building arm64 from x86

`debootstrap` needs to run arm64 binaries, so the host needs qemu binfmt. The
container route is the least painful:

```sh
docker run --privileged --rm -it \
    -v "$PWD/..:/build" -w /build/debian \
    debian:trixie \
    bash -c "apt update && apt install -y live-build qemu-user-static binfmt-support && ./build.sh"
```

`--privileged` is what lets the container register the binfmt handler. Without
it the chroot fails at the first arm64 binary.

## Boot it

**In QEMU (amd64 build):**

```sh
qemu-system-x86_64 -m 2048 -smp 2 -cdrom berrux-*-amd64.iso
```

**On real arm64 hardware:** the ISO is UEFI-bootable. Write it to a USB stick
and boot from it. A Raspberry Pi 5 needs UEFI firmware installed on it first —
the Pi's own bootloader does not boot ISO images directly. A Pi-specific image
(not an ISO) is the next piece of work, not something this directory does yet.

## What is not done

- **No image has been built yet.** This scaffold has only been validated at the
  configuration level: `auto/config` runs cleanly against live-build 20250814
  and produces the expected config files. The build itself needs root and a
  debootstrap of several hundred packages, so it has not been run.
- **No installer.** The ISO boots to a live desktop only; `--debian-installer
  none` is deliberate for the first cut. Calamares or the Debian installer is
  the next step, and a beginner needs it before Berrux is installable.
- **No wallpaper or theme branding** beyond the text files. Adding a wallpaper
  means presetting `pcmanfm-qt`'s config, which is fiddly and deserves testing
  on a real boot rather than guessing.
- **Not on the Pi 5 yet** — see the UEFI note above.

## Files

| Path | Purpose |
|---|---|
| `build.sh` | Entry point; checks for `lb` and root, then builds |
| `auto/config` | All `lb config` options, explicit and reproducible |
| `auto/build` | Runs the build and renames the ISO |
| `config/package-lists/berrux.list.chroot` | What goes in the image |
| `config/includes.chroot/` | Branding files copied in verbatim |
| `config/hooks/live/0100-berrux-branding.hook.chroot` | Adds `BERRUX_*` keys to `/etc/os-release`, enables NetworkManager |
