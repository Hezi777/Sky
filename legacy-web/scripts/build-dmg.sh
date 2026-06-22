#!/usr/bin/env bash
# Build the Sky DMG with create-dmg.
set -euo pipefail

cd "$(dirname "$0")/.."

VERSION=$(node -p "require('./package.json').version")
APP_PATH="$(pwd)/release/${VERSION}/mac-arm64/Sky.app"
DMG_PATH="$(pwd)/release/${VERSION}/Sky-${VERSION}-arm64.dmg"
BG="$(pwd)/assets/dmg/background.png"

if [ ! -d "$APP_PATH" ]; then
  echo "Error: $APP_PATH not found. Run electron-builder first."
  exit 1
fi

rm -f "$DMG_PATH"

create-dmg \
  --volname "Sky ${VERSION}" \
  --background "$BG" \
  --window-size 540 380 \
  --icon-size 80 \
  --text-size 12 \
  --icon "Sky.app" 140 200 \
  --app-drop-link 400 200 \
  --no-internet-enable \
  "$DMG_PATH" \
  "$APP_PATH"

echo ""
echo "DMG ready: $DMG_PATH"
