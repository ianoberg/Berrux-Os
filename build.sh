#!/bin/sh
#
# Build a Berrux image without retyping the Buildroot steps.
#
#   ./build.sh            Raspberry Pi 5 -> buildroot/output/images/berrux-pi5.img
#   ./build.sh generic    QEMU virt     -> buildroot/output/images/Image + rootfs.ext4
#
# Buildroot itself is downloaded once into ./buildroot, which git ignores.
# Override the version or that location with BR_VERSION / BR_DIR.
#
set -eu

TARGET="${1:-pi5}"
case "$TARGET" in
pi5 | generic) ;;
*)
	echo "usage: $0 [pi5|generic]" >&2
	exit 2
	;;
esac

DEFCONFIG="berrux_${TARGET}_defconfig"
BR_VERSION="${BR_VERSION:-2024.02.11}"
HERE="$(cd "$(dirname "$0")" && pwd)"
BR_DIR="${BR_DIR:-$HERE/buildroot}"

# Buildroot needs more than this, but these are the tools whose absence shows up
# as a confusing error halfway through the build.
MISSING=""
for tool in gcc g++ make wget tar bison flex bc cpio rsync python3 perl; do
	command -v "$tool" >/dev/null 2>&1 || MISSING="$MISSING $tool"
done
if [ -n "$MISSING" ]; then
	echo "Berrux: missing build tools:$MISSING" >&2
	echo "Berrux: on Debian/Ubuntu, sudo apt install build-essential bison flex bc cpio rsync python3 perl wget" >&2
	exit 1
fi

if [ ! -f "$BR_DIR/Makefile" ]; then
	echo "Berrux: downloading Buildroot $BR_VERSION into $BR_DIR"
	mkdir -p "$BR_DIR"
	wget -q -O "$BR_DIR/buildroot.tar.gz" \
		"https://buildroot.org/downloads/buildroot-$BR_VERSION.tar.gz"
	tar xzf "$BR_DIR/buildroot.tar.gz" -C "$BR_DIR" --strip-components=1
	rm -f "$BR_DIR/buildroot.tar.gz"
fi

export BR2_EXTERNAL="$HERE"
cd "$BR_DIR"

make "$DEFCONFIG"
make -j"$(nproc 2>/dev/null || echo 2)"

echo
if [ "$TARGET" = pi5 ]; then
	echo "Berrux: image at $BR_DIR/output/images/berrux-pi5.img"
	echo "Berrux: write it to a card with (this erases /dev/sdX):"
	echo "Berrux:   sudo dd if=$BR_DIR/output/images/berrux-pi5.img of=/dev/sdX bs=4M conv=fsync"
else
	echo "Berrux: kernel at $BR_DIR/output/images/Image"
	echo "Berrux: rootfs at $BR_DIR/output/images/rootfs.ext4"
fi
