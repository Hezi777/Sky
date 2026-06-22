#!/usr/bin/env bash
# Prepare the backend sidecar, then generate + build the unsigned macOS app.
set -euo pipefail
cd "$(dirname "$0")"

./scripts/prepare-backend.sh
xcodegen generate >/dev/null

set +e
xcodebuild -project Sky.xcodeproj -scheme Sky -configuration Debug \
  -destination 'platform=macOS' -derivedDataPath .build \
  CODE_SIGNING_ALLOWED=NO build > /tmp/sky-build.log 2>&1
code=$?
set -e

xcbeautify < /tmp/sky-build.log | tail -40 || true
if [ $code -ne 0 ]; then
  echo "--- raw errors ---"
  grep -nE "error:" /tmp/sky-build.log | head -40
fi
exit $code
