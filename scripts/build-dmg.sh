#!/usr/bin/env bash
# Build the Sky DMG with dmgbuild — deterministic, no Finder/AppleScript.
# This avoids the volume-name collisions and visible-internal-file problems
# that electron-builder's Finder-based DMG step has on recent macOS.
set -euo pipefail

cd "$(dirname "$0")/.."

VERSION=$(node -p "require('./package.json').version")
APP_PATH="$(pwd)/release/${VERSION}/mac-arm64/Sky.app"
DMG_PATH="$(pwd)/release/${VERSION}/Sky-${VERSION}-arm64.dmg"
SETTINGS="$(pwd)/electron/dmg-settings.py"

if [ ! -d "$APP_PATH" ]; then
  echo "Error: $APP_PATH not found. Run electron-builder first."
  exit 1
fi

# dmgbuild is installed under the user Python bin, which may not be on PATH.
DMGBUILD="$(command -v dmgbuild || echo "$HOME/Library/Python/3.9/bin/dmgbuild")"
if [ ! -x "$DMGBUILD" ]; then
  echo "Error: dmgbuild not found. Install with: pip3 install --user dmgbuild"
  exit 1
fi

# Rebuild the multi-resolution Retina background TIFF from the source PNGs.
tiffutil -cathidpicheck \
  assets/dmg/background.png \
  assets/dmg/background@2x.png \
  -out assets/dmg/background.tiff >/dev/null 2>&1

rm -f "$DMG_PATH"

export SKY_APP_PATH="$APP_PATH"
export SKY_BACKGROUND="$(pwd)/assets/dmg/background.tiff"
"$DMGBUILD" -s "$SETTINGS" "Sky ${VERSION}" "$DMG_PATH"

echo ""
echo "DMG ready: $DMG_PATH"
