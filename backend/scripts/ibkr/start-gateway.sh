#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
GW_DIR="$ROOT_DIR/tools/ibkr"
CONF="$GW_DIR/root/conf.yaml"
IBKR_PORT="${IBKR_GATEWAY_PORT:-5001}"

if [ ! -d "$GW_DIR" ] || [ ! -f "$CONF" ]; then
  echo "IBKR gateway is not installed yet. Run: npm run ibkr:setup"
  exit 1
fi

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
perl -0pi -e "s/listenPort:\\s*\\d+/listenPort: $IBKR_PORT/" "$CONF"

cd "$GW_DIR"
echo "Starting official IBKR Client Portal Gateway..."
echo "After it starts, open https://localhost:$IBKR_PORT and log in."
exec bin/run.sh root/conf.yaml
