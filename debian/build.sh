#!/bin/sh
#
# Build the Berrux desktop ISO.
#
#   sudo ./build.sh                     # arm64, for real hardware
#   sudo BERRUX_ARCH=amd64 ./build.sh   # x86, for a quick look in QEMU
#
set -eu
cd "$(dirname "$0")"

if ! command -v lb >/dev/null 2>&1; then
	echo "live-build is not installed." >&2
	echo "  Debian/Ubuntu: sudo apt install live-build" >&2
	echo "  From x86, cross-building arm64: see README.md" >&2
	exit 1
fi

# debootstrap and the chroot work need root. Use the container recipe in
# README.md instead if you would rather not run this as root.
if [ "$(id -u)" -ne 0 ]; then
	echo "This needs root (debootstrap + chroot). Try: sudo ./build.sh" >&2
	exit 1
fi

exec lb build "$@"
