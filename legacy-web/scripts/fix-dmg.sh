#!/usr/bin/env bash
# Fix DMG: hide .background.tiff and .VolumeIcon.icns via Finder AppleScript.
# The chflags hidden approach doesn't work reliably because Finder's .DS_Store
# view settings can override it. Instead we use AppleScript to configure the
# Finder window to not show hidden files and refresh the .DS_Store.

set -euo pipefail

DMG="$1"
if [ -z "$DMG" ] || [ ! -f "$DMG" ]; then
  echo "Usage: fix-dmg.sh <path-to.dmg>"
  exit 1
fi

WORK_DIR="$(mktemp -d)"
RW_DMG="$WORK_DIR/rw.dmg"

# Convert to read-write
hdiutil convert "$DMG" -format UDRW -o "$RW_DMG" -quiet

# Detach any existing mount of this volume name
hdiutil detach "/Volumes/Sky"* 2>/dev/null || true

# Mount read-write
DEVICE=$(hdiutil attach "$RW_DMG" -readwrite -noverify -noautoopen | grep "/Volumes/" | tail -1 | awk '{print $1}')
VOLUME=$(hdiutil attach "$RW_DMG" -readwrite -noverify -noautoopen 2>/dev/null | grep "/Volumes/" | tail -1 | sed 's|.*\(/Volumes/.*\)|\1|' || true)

# Find the mount point
VOLUME=$(df | grep "$DEVICE" | sed 's|.*/Volumes|/Volumes|' || true)
if [ -z "$VOLUME" ]; then
  VOLUME=$(mount | grep "$DEVICE" | sed 's|.* on \(/Volumes/[^ ]*\).*|\1|')
fi

echo "Volume mounted at: $VOLUME"

# Set hidden flags
chflags hidden "$VOLUME/.background.tiff" 2>/dev/null || true
chflags hidden "$VOLUME/.VolumeIcon.icns" 2>/dev/null || true

# Use AppleScript to configure Finder window — this writes a proper .DS_Store
osascript <<APPLESCRIPT
tell application "Finder"
  tell disk "$(basename "$VOLUME")"
    open
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set the bounds of container window to {100, 100, 820, 502}
    set viewOptions to the icon view options of container window
    set arrangement of viewOptions to not arranged
    set icon size of viewOptions to 92
    set background picture of viewOptions to file ".background.tiff"
    set position of item "Sky.app" of container window to {220, 218}
    set position of item "Applications" of container window to {500, 218}
    close
  end tell
end tell
APPLESCRIPT

# Wait for Finder to write .DS_Store
sleep 2

# Eject
hdiutil detach "$DEVICE" -quiet

# Convert back to compressed read-only
hdiutil convert "$RW_DMG" -format UDZO -o "$DMG" -quiet -ov

rm -rf "$WORK_DIR"
echo "Fixed: $DMG"
