#!/bin/sh
set -e
TARGET_DIR="$1"
echo "BUILT=$(date -u +%Y-%m-%d)" >> "$TARGET_DIR/etc/berrux-release"
