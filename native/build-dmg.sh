#!/usr/bin/env bash
# Package the native SwiftUI macOS app into a DMG with a styled Finder background.
#
# Why this is non-trivial on macOS 26 (Tahoe):
#  1. create-dmg styles the DMG via AppleScript, which silently fails on Tahoe —
#     the background image is copied in but no reference is written to .DS_Store,
#     so Finder shows a blank window.
#  2. dmgbuild builds .DS_Store directly in Python (no Finder), BUT versions
#     <= 1.6.5 (the latest on PyPI) also write a `pBBk` Bookmark record. macOS
#     26.2+ Finder REFUSES to render the background when that record is present
#     (dmgbuild issue #273 / PR #275). The fix landed in dmgbuild 1.6.7, which is
#     git-only (requires Python >= 3.10) and not yet on PyPI.
#  3. The background image must be 72 DPI with an embedded color profile, sized to
#     the window — a 300 DPI image renders at ~1/4 size and looks "missing".
#
# So this script provisions a local venv with the fixed dmgbuild (1.6.7) and uses
# it. The venv (native/.dmgvenv) is gitignored and auto-created on first run.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
NATIVE="$ROOT/native"
APP_PATH="$NATIVE/.build/Build/Products/Debug/Sky.app"
# Version-aware output: release/native/<MARKETING_VERSION>/Sky-native.dmg
VERSION="$(grep -E 'MARKETING_VERSION' "$NATIVE/project.yml" | head -1 | sed -E 's/.*"([0-9][0-9.]*)".*/\1/')"
VERSION="${VERSION:-0.0.0}"
OUT_DIR="$ROOT/release/native/$VERSION"
DMG_PATH="$OUT_DIR/Sky-native.dmg"
BG="$ROOT/assets/dmg/native-background.png"
SETTINGS="$NATIVE/dmgbuild-settings.py"
VENV="$NATIVE/.dmgvenv"
VENV_PY="$VENV/bin/python"
VOLNAME="Sky Native"
DMGBUILD_GIT="git+https://github.com/dmgbuild/dmgbuild.git"  # has the Tahoe pBBk fix

if [ ! -d "$APP_PATH" ]; then
  echo "Error: $APP_PATH not found. Run npm run native:build first."
  exit 1
fi

if [ ! -f "$BG" ]; then
  echo "Error: $BG not found."
  exit 1
fi

# Provision the venv with the fixed dmgbuild if it's missing or still writes pBBk.
needs_setup=0
if [ ! -x "$VENV_PY" ]; then
  needs_setup=1
elif "$VENV_PY" -c "import dmgbuild,os,sys; sys.exit(0 if 'd[\".\"][\"pBBk\"]' not in open(os.path.join(os.path.dirname(dmgbuild.__file__),'core.py')).read() else 1)"; then
  needs_setup=0
else
  needs_setup=1
fi

if [ "$needs_setup" -eq 1 ]; then
  echo "Provisioning DMG packaging venv with the Tahoe-fixed dmgbuild..."
  PY312="$(command -v python3.12 || true)"
  if [ -z "$PY312" ]; then
    echo "Error: python3.12 is required to install the fixed dmgbuild (needs Python >= 3.10)."
    echo "Install it with: brew install python@3.12"
    exit 1
  fi
  rm -rf "$VENV"
  "$PY312" -m venv "$VENV"
  "$VENV_PY" -m pip install --quiet --upgrade pip
  "$VENV_PY" -m pip install --quiet "$DMGBUILD_GIT"
fi

mkdir -p "$OUT_DIR"
rm -f "$DMG_PATH"

"$VENV_PY" -m dmgbuild \
  -s "$SETTINGS" \
  -D app="$APP_PATH" \
  -D background="$BG" \
  "$VOLNAME" \
  "$DMG_PATH"

echo "Native DMG ready: $DMG_PATH"
