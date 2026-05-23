#!/usr/bin/env bash
#
# Builds Isle.app in Release configuration and packages it into a DMG
# with a drag-to-Applications shortcut. The DMG is ad-hoc signed and
# ready for direct distribution (users will need to right-click → Open
# the first time they launch it, since it's not notarized).
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
