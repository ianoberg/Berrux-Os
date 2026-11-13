#!/bin/sh
#
# Berrux post-image script for the Raspberry Pi 5.
# Called by Buildroot as: post-image.sh
# Buildroot exports TARGET_DIR, BINARIES_DIR and BUILD_DIR for us.
#
set -eu

BOARD_DIR="$(cd "$(dirname "$0")" && pwd)"
GENIMAGE_CFG="${BOARD_DIR}/genimage.cfg"
GENIMAGE_TMP="${BUILD_DIR}/genimage.tmp"
IMAGE="${BINARIES_DIR}/berrux-pi5.img"

# genimage only reads from BINARIES_DIR, so the boot files have to be there.
cp "$BOARD_DIR/config.txt" "$BOARD_DIR/cmdline.txt" "$BINARIES_DIR"/

# genimage's own error for a missing file is a bare "no such file", which looks
# like a broken board file rather than a build that skipped a step. Name the
# cause instead of shipping an image that cannot boot.
for file in \
	config.txt cmdline.txt Image \
	bcm2712-rpi-5-b.dtb bcm2712d0-rpi-5-b.dtb bcm2712-rpi-500.dtb
do
	if [ ! -f "$BINARIES_DIR/$file" ]; then
		echo "Berrux: $BINARIES_DIR/$file is missing, so the image would not boot." >&2
		case "$file" in
		Image|*.dtb)
			echo "Berrux: check BR2_LINUX_KERNEL and BR2_LINUX_KERNEL_INTREE_DTS_NAME." >&2
			;;
		esac
		exit 1
	fi
done

if [ ! -f "$BINARIES_DIR/rootfs.ext4" ]; then
	echo "Berrux: $BINARIES_DIR/rootfs.ext4 is missing." >&2
	echo "Berrux: the SD image needs BR2_TARGET_ROOTFS_EXT2_4=y." >&2
	exit 1
fi

rm -rf "$GENIMAGE_TMP"

genimage \
	--rootpath "$TARGET_DIR" \
	--tmppath "$GENIMAGE_TMP" \
	--inputpath "$BINARIES_DIR" \
	--outputpath "$BINARIES_DIR" \
	--config "$GENIMAGE_CFG"

echo "Berrux: built $IMAGE"
echo "Berrux: write it to a card with (this erases /dev/sdX):"
echo "Berrux:   sudo dd if=$IMAGE of=/dev/sdX bs=4M conv=fsync"
