#!/usr/bin/env bash
#
# Bumps the Homebrew tap (TheVinizzz/homebrew-isle) to match a new release.
# Fetches the DMG sha256 from the GitHub Release, rewrites Casks/isle.rb,
# commits, and pushes.
#
# Usage:
#   scripts/update-cask.sh <version>          # e.g. 0.1.4
#   scripts/update-cask.sh                    # uses the version in project.yml

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TAP_DIR="${TAP_DIR:-$HOME/homebrew-isle}"

if [[ $# -ge 1 ]]; then
    VERSION="$1"
else
    VERSION=$(grep -E '^\s+CFBundleShortVersionString:' "$ROOT_DIR/project.yml" \
        | head -1 | awk -F'"' '{print $2}')
fi

[[ -n "$VERSION" ]] || { echo "✗ Could not determine version."; exit 1; }
echo "→ Bumping cask to v${VERSION}"

DMG_URL="https://github.com/TheVinizzz/Isle/releases/download/v${VERSION}/Isle-${VERSION}.dmg"

# Wait for the asset to be available (CI may still be uploading).
for attempt in {1..30}; do
    if curl -fsI "$DMG_URL" >/dev/null 2>&1; then
        break
    fi
    echo "  Asset not ready (attempt $attempt) — sleeping 10s..."
    sleep 10
done

echo "→ Computing sha256 from $DMG_URL"
SHA=$(curl -fsSL "$DMG_URL" | shasum -a 256 | awk '{print $1}')
[[ -n "$SHA" ]] || { echo "✗ Failed to compute sha256."; exit 1; }
echo "  $SHA"

if [[ ! -d "$TAP_DIR/.git" ]]; then
    echo "→ Cloning tap into $TAP_DIR"
    git clone "https://github.com/TheVinizzz/homebrew-isle.git" "$TAP_DIR"
else
    git -C "$TAP_DIR" pull --ff-only
fi

CASK="$TAP_DIR/Casks/isle.rb"
[[ -f "$CASK" ]] || { echo "✗ Cask formula not found at $CASK"; exit 1; }

echo "→ Rewriting Casks/isle.rb"
/usr/bin/sed -i '' \
    -e "s|^  version \".*\"|  version \"${VERSION}\"|" \
    -e "s|^  sha256 \".*\"|  sha256 \"${SHA}\"|" \
    "$CASK"

if git -C "$TAP_DIR" diff --quiet; then
    echo "✓ Cask already at v${VERSION}."
    exit 0
fi

git -C "$TAP_DIR" add Casks/isle.rb
git -C "$TAP_DIR" commit -m "chore: bump isle to ${VERSION}"
git -C "$TAP_DIR" push origin main

echo "✓ Tap pushed."
