#!/bin/bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/build"
DIST_DIR="$PROJECT_ROOT/dist"
APP_BUNDLE="$BUILD_DIR/SteamPack.app"
DMG_NAME="SteamPack"

[ -d "$APP_BUNDLE" ] || { echo "Error: Build first (scripts/build.sh)"; exit 1; }

mkdir -p "$DIST_DIR"
rm -f "$DIST_DIR/$DMG_NAME.dmg"

# Staging directory for DMG contents
STAGING="$BUILD_DIR/dmg-staging"
rm -rf "$STAGING"
mkdir -p "$STAGING"
cp -R "$APP_BUNDLE" "$STAGING/"
ln -s /Applications "$STAGING/Applications"

# Create DMG
hdiutil create \
    -volname "$DMG_NAME" \
    -srcfolder "$STAGING" \
    -ov \
    -format UDZO \
    "$DIST_DIR/$DMG_NAME.dmg"

rm -rf "$STAGING"

echo "=== DMG created ==="
echo "  $DIST_DIR/$DMG_NAME.dmg"
