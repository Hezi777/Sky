#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
IBKR_DIR="$ROOT_DIR/tools/ibkr"
ZIP_PATH="$IBKR_DIR/clientportal.gw.zip"
GW_DIR="$IBKR_DIR"
URL="https://download2.interactivebrokers.com/portal/clientportal.gw.zip"
IBKR_PORT="${IBKR_GATEWAY_PORT:-5001}"

mkdir -p "$IBKR_DIR"

JAVA_BIN="${JAVA_BIN:-}"
if [ -z "$JAVA_BIN" ]; then
  if [ -x "/opt/homebrew/opt/openjdk/bin/java" ]; then
    JAVA_BIN="/opt/homebrew/opt/openjdk/bin/java"
  elif [ -x "/usr/local/opt/openjdk/bin/java" ]; then
    JAVA_BIN="/usr/local/opt/openjdk/bin/java"
  elif command -v java >/dev/null 2>&1; then
    JAVA_BIN="$(command -v java)"
  else
    echo "Java is required for IBKR Client Portal Gateway."
    echo "On macOS: brew install openjdk"
    exit 1
  fi
fi
export PATH="$(dirname "$JAVA_BIN"):$PATH"

if [ ! -f "$GW_DIR/root/conf.yaml" ]; then
  echo "Downloading official IBKR Client Portal Gateway..."
  curl -L "$URL" -o "$ZIP_PATH"
  echo "Unzipping gateway..."
  find "$IBKR_DIR" -mindepth 1 ! -name "clientportal.gw.zip" -exec rm -rf {} +
  unzip -q "$ZIP_PATH" -d "$IBKR_DIR"
else
  echo "Gateway already exists at $GW_DIR"
fi

perl -0pi -e "s/listenPort:\\s*\\d+/listenPort: $IBKR_PORT/" "$GW_DIR/root/conf.yaml"

echo "Ready: $GW_DIR"
echo "Configured gateway port: $IBKR_PORT"
echo "Run: npm run ibkr:start"
