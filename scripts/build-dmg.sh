#!/usr/bin/env bash
#
# Builds Isle.app in Release configuration and packages it into a DMG
# with a drag-to-Applications shortcut, plus an "Install Isle.command"
# script that automates the install for users who'd rather not deal
# with Gatekeeper warnings.
#
# Usage:
#   scripts/build-dmg.sh
#
# Output:
#   dist/Isle-<version>.dmg

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

echo "→ Regenerating Xcode project..."
xcodegen generate >/dev/null

echo "→ Building Release..."
DERIVED="$ROOT_DIR/build"
rm -rf "$DERIVED"
xcodebuild \
    -project Isle.xcodeproj \
    -scheme Isle \
    -configuration Release \
    -derivedDataPath "$DERIVED" \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGNING_REQUIRED=NO \
    ENABLE_HARDENED_RUNTIME=NO \
    build | xcpretty 2>/dev/null || true

APP_PATH="$DERIVED/Build/Products/Release/Isle.app"
if [[ ! -d "$APP_PATH" ]]; then
    echo "✗ Build artifact not found at $APP_PATH"
    exit 1
fi

VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP_PATH/Contents/Info.plist")
DMG_NAME="Isle-${VERSION}.dmg"
DIST="$ROOT_DIR/dist"
STAGE="$DIST/stage"

echo "→ Staging DMG layout..."
rm -rf "$DIST"
mkdir -p "$STAGE"
cp -R "$APP_PATH" "$STAGE/"
ln -s /Applications "$STAGE/Applications"

# Bundle a one-click installer that clears the quarantine attribute so
# users can launch without "Apple cannot verify this app" prompts.
cat > "$STAGE/Install Isle.command" <<'INSTALLER_EOF'
#!/bin/bash
# Installs Isle to /Applications and clears the macOS quarantine flag
# so the first launch doesn't trigger a Gatekeeper warning.

set -e

cd "$(dirname "$0")"

APP_NAME="Isle"
SRC="${APP_NAME}.app"
DEST="/Applications/${APP_NAME}.app"

if [[ ! -d "$SRC" ]]; then
    osascript -e 'display dialog "Isle.app not found beside this installer. Open the DMG first, then run this script from inside the mounted volume." buttons {"OK"} default button "OK" with icon stop' >/dev/null || true
    exit 1
fi

echo "→ Stopping running Isle (if any)..."
killall "$APP_NAME" 2>/dev/null || true
sleep 1

echo "→ Installing to ${DEST}..."
rm -rf "$DEST"
cp -R "$SRC" "$DEST"

echo "→ Clearing Gatekeeper quarantine attribute..."
xattr -dr com.apple.quarantine "$DEST" 2>/dev/null || true

echo "→ Launching Isle..."
open "$DEST"

osascript -e 'display notification "Isle is now installed and running. Look for the icon in the menu bar." with title "Isle" sound name "Glass"' >/dev/null || true

echo ""
echo "✓ Done. You can close this Terminal window."
INSTALLER_EOF
chmod +x "$STAGE/Install Isle.command"

# Plain-text README inside the DMG for users who prefer the manual path.
cat > "$STAGE/README.txt" <<'README_EOF'
Isle — install guide

OPTION A (recommended) — automated:
   Double-click "Install Isle.command".
   Terminal opens briefly, installs Isle, and launches it.

OPTION B — manual:
   1. Drag Isle.app onto the Applications shortcut.
   2. Open Applications, right-click Isle, choose Open.
   3. Confirm the Gatekeeper prompt that appears (only required once).

After install, look for the Isle icon in your menu bar.
First launch will request Calendar and Automation permissions — accept them so
the calendar widget and music controls can do their thing.

A faster option exists if you have Terminal handy:
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/TheVinizzz/Isle/main/scripts/install.sh)"
README_EOF

echo "→ Creating $DMG_NAME..."
hdiutil create \
    -volname "Isle" \
    -srcfolder "$STAGE" \
    -ov \
    -format UDZO \
    -fs HFS+ \
    "$DIST/$DMG_NAME" >/dev/null

rm -rf "$STAGE"

echo "✓ $DIST/$DMG_NAME"
echo "  Size: $(du -h "$DIST/$DMG_NAME" | cut -f1)"
