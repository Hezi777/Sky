#!/usr/bin/env bash
# Build and stage the self-contained Next.js backend sidecar for the macOS app.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
BACKEND="$ROOT/backend"
RESOURCE_PARENT="$ROOT/native/Resources"
RESOURCE_DIR="$RESOURCE_PARENT/SkyBackend"
NODE_BINARY="${SKY_NODE_BINARY:-}"
NPM_BINARY="$(command -v npm || true)"
REQUIRED_NODE_VERSION="24.15.0"
REQUIRED_NODE_ARCH="arm64"

if [ -z "$NODE_BINARY" ]; then
  CURRENT_NODE="$(command -v node || true)"
  if [ -n "$CURRENT_NODE" ] && \
    [ "$($CURRENT_NODE -p 'process.versions.node' 2>/dev/null || true)" = "$REQUIRED_NODE_VERSION" ] && \
    [ "$($CURRENT_NODE -p 'process.arch' 2>/dev/null || true)" = "$REQUIRED_NODE_ARCH" ]; then
    NODE_BINARY="$CURRENT_NODE"
  else
    shopt -s nullglob
    NODE_24_CANDIDATES=(
      "$HOME/.nvm/versions/node/v$REQUIRED_NODE_VERSION/bin/node"
      /opt/homebrew/opt/node@24/bin/node
    )
    shopt -u nullglob
    for candidate in "${NODE_24_CANDIDATES[@]}"; do
      if [ -x "$candidate" ]; then
        NODE_BINARY="$candidate"
      fi
    done
  fi
fi

if [ -z "$NODE_BINARY" ] || [ ! -x "$NODE_BINARY" ]; then
  echo "Error: a Node.js executable is required (set SKY_NODE_BINARY to override)."
  exit 1
fi
NODE_BINARY="$(cd "$(dirname "$NODE_BINARY")" && pwd)/$(basename "$NODE_BINARY")"

NODE_VERSION="$($NODE_BINARY -p 'process.versions.node')"
NODE_ARCH="$($NODE_BINARY -p 'process.arch')"
if [ "$NODE_VERSION" != "$REQUIRED_NODE_VERSION" ] || [ "$NODE_ARCH" != "$REQUIRED_NODE_ARCH" ]; then
  echo "Error: Node.js v$REQUIRED_NODE_VERSION $REQUIRED_NODE_ARCH is required; found v$NODE_VERSION $NODE_ARCH at $NODE_BINARY."
  exit 1
fi

if [ -z "$NPM_BINARY" ] || [ ! -x "$NPM_BINARY" ]; then
  echo "Error: npm is required to build the backend."
  exit 1
fi

mkdir -p "$RESOURCE_PARENT"
BUILD_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/sky-backend-build.XXXXXX")"
OUTPUT_DIR="$(mktemp -d "$RESOURCE_PARENT/.SkyBackend.tmp.XXXXXX")"
cleanup() {
  rm -rf "$BUILD_ROOT" "$OUTPUT_DIR"
}
trap cleanup EXIT

STAGED_BACKEND="$BUILD_ROOT/backend"
mkdir -p "$STAGED_BACKEND"
rsync -a \
  --exclude='.env*' \
  --exclude='.git/' \
  --exclude='.next/' \
  --exclude='node_modules/' \
  --exclude='coverage/' \
  "$BACKEND/" "$STAGED_BACKEND/"

if find "$STAGED_BACKEND" -name '.env*' -print -quit | grep -q .; then
  echo "Error: an environment file entered the clean backend staging directory."
  exit 1
fi

# npm's launcher resolves `node` through PATH. Pin that lookup to the validated
# executable while keeping the build environment free of inherited dev secrets.
mkdir -p "$BUILD_ROOT/bin" "$BUILD_ROOT/npm-cache"
ln -s "$NODE_BINARY" "$BUILD_ROOT/bin/node"
BUILD_PATH="$BUILD_ROOT/bin:$(dirname "$NPM_BINARY"):/usr/bin:/bin:/usr/sbin:/sbin"

(
  cd "$STAGED_BACKEND"
  env -i \
    HOME="$HOME" \
    PATH="$BUILD_PATH" \
    TMPDIR="${TMPDIR:-/tmp}" \
    CI=1 \
    NODE_ENV=development \
    NEXT_TELEMETRY_DISABLED=1 \
    npm_config_cache="$BUILD_ROOT/npm-cache" \
    "$NPM_BINARY" ci
  env -i \
    HOME="$HOME" \
    PATH="$BUILD_PATH" \
    TMPDIR="${TMPDIR:-/tmp}" \
    CI=1 \
    NODE_ENV=production \
    NEXT_TELEMETRY_DISABLED=1 \
    npm_config_cache="$BUILD_ROOT/npm-cache" \
    "$NPM_BINARY" run build
)

STANDALONE="$STAGED_BACKEND/.next/standalone"
STATIC="$STAGED_BACKEND/.next/static"
if [ ! -f "$STANDALONE/server.js" ] || [ ! -d "$STATIC" ]; then
  echo "Error: Next.js did not produce the expected standalone server output."
  exit 1
fi

mkdir -p "$OUTPUT_DIR/server/.next"
cp -R "$STANDALONE/." "$OUTPUT_DIR/server/"
cp -R "$STATIC" "$OUTPUT_DIR/server/.next/static"
if [ -d "$STAGED_BACKEND/public" ]; then
  cp -R "$STAGED_BACKEND/public" "$OUTPUT_DIR/server/public"
fi
cp "$NODE_BINARY" "$OUTPUT_DIR/node"
chmod 755 "$OUTPUT_DIR/node"
touch "$OUTPUT_DIR/.gitkeep"

if find "$OUTPUT_DIR" -name '.env*' -print -quit | grep -q .; then
  echo "Error: an environment file entered the backend app resources."
  exit 1
fi

rm -rf "$RESOURCE_DIR"
mv "$OUTPUT_DIR" "$RESOURCE_DIR"
echo "Backend resources ready: $RESOURCE_DIR ($(du -sh "$RESOURCE_DIR" | awk '{print $1}'))"
