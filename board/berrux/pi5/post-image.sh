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

# genimage only reads from BINARIES_DIR, so the boot files have to be there.
cp "$BOARD_DIR/config.txt" "$BOARD_DIR/cmdline.txt" "$BINARIES_DIR"/

rm -rf "$GENIMAGE_TMP"

genimage \
	--rootpath "$TARGET_DIR" \
	--tmppath "$GENIMAGE_TMP" \
	--inputpath "$BINARIES_DIR" \
	--outputpath "$BINARIES_DIR" \
	--config "$GENIMAGE_CFG"

echo "Berrux: built $BINARIES_DIR/berrux-pi5.img"
