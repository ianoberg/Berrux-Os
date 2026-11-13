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

RELEASE="$TARGET_DIR/etc/berrux-release"
ARCH="unknown"
TARGET_NAME=""

# The overlay ships a human-readable target ("Raspberry Pi 5"). Keep it if it is
# there rather than replacing it with a defconfig name.
if [ -r "$RELEASE" ]; then
	TARGET_NAME="$(sed -n 's/^TARGET=//p' "$RELEASE" | head -n 1)"
fi

if [ -n "$CONFIG" ] && [ -r "$CONFIG" ]; then
	ARCH="$(sed -n 's/^BR2_ARCH="\([^"]*\)"$/\1/p' "$CONFIG" | head -n 1)"
	[ -n "$ARCH" ] || ARCH="unknown"

	# Fallback only: berrux_pi5_defconfig -> pi5
	if [ -z "$TARGET_NAME" ]; then
		CFG_NAME="$(basename "$CONFIG")"
		CFG_NAME="${CFG_NAME%_defconfig}"
		TARGET_NAME="${CFG_NAME#berrux_}"
	fi
fi

[ -n "$TARGET_NAME" ] || TARGET_NAME="generic"

# Always rewrite the whole file: the target dir persists between builds, so
# appending would pile up duplicate lines.
mkdir -p "$TARGET_DIR/etc"
{
	echo "NAME=Berrux"
	echo "AUTHORS=Ian, with help from Mischa"
	echo "TARGET=$TARGET_NAME"
	echo "ARCH=$ARCH"
	echo "BUILT=$(date -u +%Y-%m-%d)"
} > "$RELEASE"

echo "Berrux: stamped $RELEASE (target=$TARGET_NAME arch=$ARCH)"
