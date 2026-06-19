# Sky Native — Build Runbook

SwiftUI multiplatform app for macOS 26 and iOS 26, driven entirely from the CLI.

**Toolchain:** Xcode 26.5, Swift 6.3, xcodegen, xcbeautify (Homebrew), macOS 26.5.

---

## 1. Project Structure

```
native/
├── project.yml              # XcodeGen spec
├── Sky/
│   ├── SkyApp.swift          # @main entry point
│   ├── ContentView.swift
│   └── Assets.xcassets/
│       └── AccentColor.colorset/
│           └── Contents.json
└── docs/
    └── build-runbook.md      # this file
```

---

## 2. project.yml

**Decision: ONE multiplatform target using `supportedDestinations: [iOS, macOS]`.**

This is the genuine best practice since Xcode 14+. XcodeGen maps `supportedDestinations`
to the `SUPPORTED_PLATFORMS` build setting and sets `SUPPORTS_MACCATALYST = NO` (this is
a native macOS build, not Catalyst). Two separate targets sharing sources is unnecessary
overhead — a single target with `supportedDestinations` produces one scheme that builds
for both platforms.

```yaml
# native/project.yml
name: Sky
options:
  bundleIdPrefix: com.hen.sky
  deploymentTarget:
    macOS: "26.0"
    iOS: "26.0"
  xcodeVersion: "26.5"
  generateEmptyDirectories: true
  createIntermediateGroups: true
  defaultConfig: Release

settings:
  base:
    SWIFT_VERSION: "6.0"
    ENABLE_USER_SCRIPT_SANDBOXING: "YES"
    CODE_SIGN_STYLE: Automatic
    # Replace YOUR_TEAM_ID with your 10-char Apple Team ID (or leave blank for Personal Team)
    DEVELOPMENT_TEAM: ""
    SWIFT_STRICT_CONCURRENCY: complete

targets:
  Sky:
    type: application
    supportedDestinations: [macOS, iOS]
    deploymentTarget:
      macOS: "26.0"
      iOS: "26.0"
    sources:
      - path: Sky
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.hen.sky.native
        PRODUCT_NAME: Sky
        GENERATE_INFOPLIST_FILE: "YES"
        INFOPLIST_KEY_CFBundleDisplayName: Sky
        INFOPLIST_KEY_UIApplicationSceneManifest_Generation: "YES"
        INFOPLIST_KEY_UILaunchScreen_Generation: "YES"
        INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad: "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight"
        INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone: "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight"
        ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon
        MARKETING_VERSION: "1.0.0"
        CURRENT_PROJECT_VERSION: "1"
        ENABLE_PREVIEWS: "YES"
    scheme:
      gatherCoverageData: false
```

### What this produces

- `SUPPORTED_PLATFORMS = "iphoneos iphonesimulator macosx"`
- One scheme named "Sky" with destinations for My Mac and iOS Simulators.
- Info.plist is auto-generated from `INFOPLIST_KEY_*` build settings (no manual plist file).
- SwiftUI lifecycle via `UIApplicationSceneManifest_Generation`.
- Code signing set to Automatic — works with free Personal Team (leave `DEVELOPMENT_TEAM` empty string or set your Team ID).

---

## 3. Starter Swift Files

These must exist before `xcodegen generate` (it validates source paths).

### Sky/SkyApp.swift

```swift
import SwiftUI

@main
struct SkyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### Sky/ContentView.swift

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "cloud.sun.fill")
                .font(.system(size: 72))
                .symbolRenderingMode(.multicolor)
            Text("Sky")
                .font(.largeTitle)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
```

### Sky/Assets.xcassets/Contents.json

```json
{
  "info": {
    "author": "xcode",
    "version": 1
  }
}
```

---

## 4. Generate + Build + Run Commands

All commands assume `cd native/` as working directory.

### 4.1 Generate Xcode Project

```bash
cd native && xcodegen generate
```

Expected output: `⚙  Generating plists...` → `Created project at Sky.xcodeproj`

### 4.2 Build for macOS

```bash
xcodebuild \
  -project Sky.xcodeproj \
  -scheme Sky \
  -configuration Release \
  -destination 'platform=macOS' \
  -derivedDataPath .build \
  build 2>&1 | xcbeautify
```

### 4.3 Locate and Launch on macOS

```bash
# Find the .app
APP_PATH=$(find .build -path "*/Release/Sky.app" -type d | head -1)
echo "Built app: $APP_PATH"

# Launch and bring to foreground
open "$APP_PATH"
```

### 4.4 One-Liner: Build + Run macOS

```bash
xcodebuild -project Sky.xcodeproj -scheme Sky -configuration Release \
  -destination 'platform=macOS' -derivedDataPath .build build 2>&1 \
  | xcbeautify && open "$(find .build -path '*/Release/Sky.app' -type d | head -1)"
```

### 4.5 Build + Run on iOS Simulator

#### Step 1: Find the exact simulator device name

```bash
xcrun simctl list devices available | grep -i "iphone"
```

Pick a device name from the output (e.g., `iPhone 16 Pro`).

#### Step 2: Boot the simulator

```bash
DEVICE_NAME="iPhone 16 Pro"
xcrun simctl boot "$DEVICE_NAME" 2>/dev/null || true
```

#### Step 3: Build for iOS Simulator

```bash
xcodebuild \
  -project Sky.xcodeproj \
  -scheme Sky \
  -configuration Debug \
  -destination "platform=iOS Simulator,name=$DEVICE_NAME" \
  -derivedDataPath .build \
  build 2>&1 | xcbeautify
```

#### Step 4: Install and launch

```bash
# Find the simulator .app (it's under Debug-iphonesimulator, not Release)
SIM_APP=$(find .build -path "*/Debug-iphonesimulator/Sky.app" -type d | head -1)

# Install
xcrun simctl install booted "$SIM_APP"

# Launch (bundle ID, not path)
xcrun simctl launch booted com.hen.sky.native

# Bring Simulator.app to foreground
open -a Simulator
```

#### Full iOS one-liner

```bash
DEVICE_NAME="iPhone 16 Pro" && \
xcrun simctl boot "$DEVICE_NAME" 2>/dev/null; \
xcodebuild -project Sky.xcodeproj -scheme Sky -configuration Debug \
  -destination "platform=iOS Simulator,name=$DEVICE_NAME" \
  -derivedDataPath .build build 2>&1 | xcbeautify && \
xcrun simctl install booted "$(find .build -path '*/Debug-iphonesimulator/Sky.app' -type d | head -1)" && \
xcrun simctl launch booted com.hen.sky.native && \
open -a Simulator
```

### 4.6 Screenshots

#### iOS Simulator screenshot

```bash
xcrun simctl io booted screenshot sim-screenshot.png
```

#### macOS app window screenshot

```bash
# Screenshot a specific window by app name
screencapture -l $(osascript -e 'tell app "System Events" to tell process "Sky" to get the id of window 1') mac-screenshot.png
```

Or simpler (interactive window pick):

```bash
screencapture -w mac-screenshot.png
```

---

## 5. Common Failure Modes & Fixes (2026)

### 5.1 Signing errors on free Personal Team

**Symptom:** `Signing requires a development team. Select a development team in the Signing & Capabilities editor.`

**Fix:** Set `DEVELOPMENT_TEAM` in project.yml or pass it on the command line:

```bash
xcodebuild ... DEVELOPMENT_TEAM="YOUR_TEAM_ID" build 2>&1 | xcbeautify
```

Find your Team ID:

```bash
security find-identity -v -p codesigning | head -5
```

Or for local-only builds, disable signing entirely:

```bash
xcodebuild ... CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO build 2>&1 | xcbeautify
```

### 5.2 "No such module" errors

**Symptom:** `No such module 'SomePackage'`

**Causes & fixes:**
- SPM packages not resolved: run `xcodebuild -resolvePackageDependencies -project Sky.xcodeproj`
- Wrong derived data: delete `.build/` and rebuild
- Architecture mismatch: ensure destination matches (don't build macOS binary and try to import from iOS target)

### 5.3 Simulator not found / wrong runtime name

**Symptom:** `Unable to find a destination matching the provided destination specifier`

**Fix:** List available simulators and match the name exactly:

```bash
# List all available devices
xcrun simctl list devices available

# List available runtimes
xcrun simctl list runtimes

# If no iOS 26 simulators exist, create one
xcrun simctl create "iPhone 16 Pro" "com.apple.CoreSimulator.SimDeviceType.iPhone-16-Pro" "com.apple.CoreSimulator.SimRuntime.iOS-26-0"
```

**Key gotcha:** Runtime identifiers use dashes not dots: `iOS-26-0` not `iOS.26.0`.

### 5.4 Derived data staleness

**Symptom:** Incremental build produces stale artifacts, crashes, or mysterious link errors.

**Fix:**

```bash
# Nuclear option — delete derived data for this project
rm -rf .build

# Or clean via xcodebuild
xcodebuild -project Sky.xcodeproj -scheme Sky clean 2>&1 | xcbeautify
```

### 5.5 Sandbox script errors (ENABLE_USER_SCRIPT_SANDBOXING)

**Symptom:** `Build phase 'Run Script' was blocked by the sandbox`

**Cause:** Script build phases that access files outside the sandbox. Since we set `ENABLE_USER_SCRIPT_SANDBOXING: YES` (required for modern Xcode), any Run Script phase must declare its inputs/outputs explicitly.

**Fix options:**
1. Declare all input/output files in the script phase.
2. If using a third-party tool that can't comply, set `ENABLE_USER_SCRIPT_SANDBOXING: NO` in the target's settings (not recommended).

For a clean SwiftUI-only project with no script phases, this should never fire.

### 5.6 Swift 6 concurrency errors

**Symptom:** `Sending 'self' risks causing data races`

**Fix:** We set `SWIFT_STRICT_CONCURRENCY: complete`. This enforces full concurrency checking. Mark types as `@Sendable`, `@MainActor`, or `nonisolated` as needed. For a simple SwiftUI app, annotate your views with `@MainActor` if the compiler complains.

### 5.7 Quick diagnostic commands

```bash
# Xcode version
xcodebuild -version

# Available SDKs
xcodebuild -showsdks

# Available simulators (filter for iPhone)
xcrun simctl list devices available | grep -i "iphone"

# Xcode select path (must be /Applications/Xcode.app/Contents/Developer)
xcode-select -p

# List schemes in the project
xcodebuild -project Sky.xcodeproj -list
```

---

## Sources

- [XcodeGen ProjectSpec documentation](https://github.com/yonaskolb/XcodeGen/blob/master/Docs/ProjectSpec.md)
- [XcodeGen test fixture — project.yml with supportedDestinations](https://github.com/yonaskolb/XcodeGen/blob/master/Tests/Fixtures/TestProject/project.yml)
- [XcodeGen GitHub repository](https://github.com/yonaskolb/XcodeGen)
- [xcbeautify — xcodebuild formatter](https://github.com/cpisciotta/xcbeautify)
- [Apple Developer Forums — xcodebuild destination for macOS](https://developer.apple.com/forums/thread/757680)
