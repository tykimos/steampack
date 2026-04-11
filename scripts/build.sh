#!/bin/bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/build"
APP_BUNDLE="$BUILD_DIR/SteamPack.app"

echo "=== SteamPack Build ==="

rm -rf "$APP_BUNDLE"

# --- 1. Build App ---
echo "[1/3] Building SteamPack.app..."
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$PROJECT_ROOT/AppInfo.plist" "$APP_BUNDLE/Contents/Info.plist"
# Copy icon if available
[ -f "$PROJECT_ROOT/resources/AppIcon.icns" ] && \
    cp "$PROJECT_ROOT/resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
echo -n "APPLSTPK" > "$APP_BUNDLE/Contents/PkgInfo"

# arm64 build
swiftc \
    -target arm64-apple-macosx13.0 \
    -module-name SteamPack \
    -framework Cocoa \
    -framework Security \
    -o "$APP_BUNDLE/Contents/MacOS/SteamPack-arm64" \
    "$PROJECT_ROOT/src/AppMain.swift" \
    "$PROJECT_ROOT/src/SleepToggle.swift" \
    "$PROJECT_ROOT/src/KeychainHelper.swift" \
    "$PROJECT_ROOT/src/PasswordPrompt.swift"

# x86_64 build (optional - may fail on arm64-only environments)
swiftc \
    -target x86_64-apple-macosx13.0 \
    -module-name SteamPack \
    -framework Cocoa \
    -framework Security \
    -o "$APP_BUNDLE/Contents/MacOS/SteamPack-x86_64" \
    "$PROJECT_ROOT/src/AppMain.swift" \
    "$PROJECT_ROOT/src/SleepToggle.swift" \
    "$PROJECT_ROOT/src/KeychainHelper.swift" \
    "$PROJECT_ROOT/src/PasswordPrompt.swift" 2>/dev/null || true

# Universal Binary (if x86_64 succeeded)
if [ -f "$APP_BUNDLE/Contents/MacOS/SteamPack-x86_64" ]; then
    lipo -create \
        "$APP_BUNDLE/Contents/MacOS/SteamPack-arm64" \
        "$APP_BUNDLE/Contents/MacOS/SteamPack-x86_64" \
        -output "$APP_BUNDLE/Contents/MacOS/SteamPack"
    rm "$APP_BUNDLE/Contents/MacOS/SteamPack-arm64" "$APP_BUNDLE/Contents/MacOS/SteamPack-x86_64"
else
    mv "$APP_BUNDLE/Contents/MacOS/SteamPack-arm64" "$APP_BUNDLE/Contents/MacOS/SteamPack"
fi

echo "  ✓ SteamPack.app"

# --- 2. Code Sign ---
echo "[2/3] Code signing..."
codesign --force --sign - "$APP_BUNDLE" 2>&1
echo "  ✓ Signed (ad-hoc)"

# --- 3. Verify ---
echo "[3/3] Verifying..."
[ -f "$APP_BUNDLE/Contents/MacOS/SteamPack" ] || { echo "  ✗ Binary missing"; exit 1; }
[ -f "$APP_BUNDLE/Contents/Info.plist" ] || { echo "  ✗ Info.plist missing"; exit 1; }
echo "  ✓ All verified"

echo ""
echo "=== Build complete ==="
echo "  $APP_BUNDLE"
