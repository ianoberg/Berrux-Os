#!/bin/sh
#
# Berrux post-build script.
# Called by Buildroot as: post-build.sh <TARGET_DIR>
#
set -eu

TARGET_DIR="$1"

# Buildroot exports BR2_CONFIG to post-build scripts; fall back to the usual
# default in case this is run by hand.
CONFIG="${BR2_CONFIG:-}"

ARCH="unknown"
TARGET_NAME="generic"
if [ -n "$CONFIG" ] && [ -r "$CONFIG" ]; then
	ARCH="$(sed -n 's/^BR2_ARCH="\([^"]*\)"$/\1/p' "$CONFIG" | head -n 1)"
	[ -n "$ARCH" ] || ARCH="unknown"

	# berrux_pi5_defconfig -> pi5, berrux_generic_aarch64_defconfig -> generic_aarch64
	CFG_NAME="$(basename "$CONFIG")"
	CFG_NAME="${CFG_NAME%_defconfig}"
	TARGET_NAME="${CFG_NAME#berrux_}"
	[ -n "$TARGET_NAME" ] || TARGET_NAME="generic"
fi

# Always rewrite the whole file: the target dir persists between builds, so
# appending would pile up duplicate lines.
mkdir -p "$TARGET_DIR/etc"
{
	echo "NAME=Berrux"
	echo "AUTHORS=Ian, with help from Mischa"
	echo "TARGET=$TARGET_NAME"
	echo "ARCH=$ARCH"
	echo "BUILT=$(date -u +%Y-%m-%d)"
} > "$TARGET_DIR/etc/berrux-release"

echo "Berrux: stamped $TARGET_DIR/etc/berrux-release (target=$TARGET_NAME arch=$ARCH)"
