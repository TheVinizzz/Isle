#!/usr/bin/env bash
#
# Isle one-line remote installer.
#
# Usage:
#   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/TheVinizzz/Isle/main/scripts/install.sh)"
#
# This bypasses macOS Gatekeeper because curl-downloaded files don't get the
# `com.apple.quarantine` attribute that browsers attach. We still clear the
# attribute after install (defense in depth).

set -euo pipefail

REPO="TheVinizzz/Isle"
APP_NAME="Isle"
APP_PATH="/Applications/${APP_NAME}.app"

color() {
    printf '\033[%sm%s\033[0m' "$1" "$2"
}

step() { echo "$(color "36" "→") $1"; }
ok() { echo "$(color "32" "✓") $1"; }
warn() { echo "$(color "33" "!") $1" >&2; }
fail() { echo "$(color "31" "✗") $1" >&2; exit 1; }

# 1. macOS check
[[ "$(uname -s)" == "Darwin" ]] || fail "Isle requires macOS."

# 2. macOS version check (14.0+)
SW_VERS="$(sw_vers -productVersion)"
SW_MAJOR="${SW_VERS%%.*}"
if (( SW_MAJOR < 14 )); then
    fail "Isle requires macOS 14.0 or newer (you have $SW_VERS)."
fi

# 3. Apple Silicon check
ARCH="$(uname -m)"
if [[ "$ARCH" != "arm64" ]]; then
    warn "Isle is designed for Apple Silicon — your Mac reports $ARCH. Install will continue, but the app won't detect a notch on Intel Macs."
fi

# 4. Fetch latest release DMG URL
step "Fetching latest release..."
DMG_URL="$(
    curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" \
        | grep -oE '"browser_download_url": *"[^"]+\.dmg"' \
        | head -1 \
        | sed -E 's/.*"([^"]+)".*/\1/'
)"

[[ -n "$DMG_URL" ]] || fail "Could not find a DMG asset in the latest release."

DMG_FILE="$(basename "$DMG_URL")"
ok "Latest: $DMG_FILE"

# 5. Download to temp
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

step "Downloading $DMG_FILE..."
curl --progress-bar --fail --location "$DMG_URL" -o "$TMP/$DMG_FILE"

# 6. Stop any running instance
if pgrep -x "$APP_NAME" >/dev/null; then
    step "Stopping running Isle..."
    killall "$APP_NAME" 2>/dev/null || true
    sleep 1
fi

# 7. Mount + copy + unmount
step "Mounting DMG..."
MOUNT="$(hdiutil attach "$TMP/$DMG_FILE" -nobrowse -noverify | tail -1 | awk -F'\t' '{print $NF}')"
[[ -d "$MOUNT/${APP_NAME}.app" ]] || { hdiutil detach "$MOUNT" -quiet; fail "${APP_NAME}.app not found inside DMG."; }

step "Installing to $APP_PATH..."
rm -rf "$APP_PATH" 2>/dev/null || true
cp -R "$MOUNT/${APP_NAME}.app" /Applications/
hdiutil detach "$MOUNT" -quiet

# 8. Clear quarantine (defense in depth — curl shouldn't have set it, but doesn't hurt)
xattr -dr com.apple.quarantine "$APP_PATH" 2>/dev/null || true

# 9. Launch
step "Launching Isle..."
open "$APP_PATH"

echo ""
ok "Isle is installed."
echo "  Look for the icon in your menu bar."
echo "  Hover the notch — the panel will expand."
echo ""
echo "  Grant Calendar + Automation permissions when prompted."
echo "  Open the status-bar menu → Launch at Login if you want it on boot."
