#!/usr/bin/env bash
# Generate + build the macOS app locally (unsigned — no team needed, runs like
# the Electron app). Preserves xcodebuild's real exit code.
set -uo pipefail
cd "$(dirname "$0")"

xcodegen generate >/dev/null

xcodebuild -project Sky.xcodeproj -scheme Sky -configuration Debug \
  -destination 'platform=macOS' -derivedDataPath .build \
  CODE_SIGNING_ALLOWED=NO build > /tmp/sky-build.log 2>&1
code=$?

xcbeautify < /tmp/sky-build.log | tail -40 || true
if [ $code -ne 0 ]; then
  echo "--- raw errors ---"
  grep -nE "error:" /tmp/sky-build.log | head -40
fi
exit $code
