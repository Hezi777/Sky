# Sky Desktop

Sky packaged as a desktop app (Electron) for macOS and Windows. The web app runs the same way; this wraps it in a native shell with its own config and logs.

---

## Build locally

```bash
npm run electron:build
```

Output goes to a versioned folder under `release/`, using the `package.json` version:

- macOS: `.dmg` and `.zip` (arm64)
- Windows: NSIS `.exe` (x64)

For example, version `0.1.1` builds to `release/0.1.1/`.

Builds are unsigned (ad-hoc on macOS).

### macOS icon (Liquid Glass)

The macOS app icon is a native Icon Composer bundle (`public/Mac Icon.icon`), which adapts to light, dark, and tinted Dock modes on macOS 26+. electron-builder generates the adaptive `Assets.car` plus a fallback `.icns` automatically, but this requires full Xcode 26+ (the `actool` from Command Line Tools alone is too old).

If `xcode-select` points at the Command Line Tools instead of Xcode, run the build with:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer npm run electron:build
```

On machines without Xcode 26+, fall back to the prebuilt `.icns`:

```bash
npx electron-builder --mac --config.mac.icon=electron/build/icon.icns
```

After reinstalling the app, the Dock may show a stale cached icon — run `killall Dock` to refresh it.

## Dev mode

```bash
npm run electron:dev
```

Runs the Next.js dev server inside the Electron shell.

## Configuration (`.env`)

The packaged app reads secrets from a `.env` file in Electron's userData directory:

- macOS: `~/Library/Application Support/Sky/.env`
- Windows: `%APPDATA%\Sky\.env`

**First run:** the app copies a template `.env` into that folder and shows a dialog with an "Open Folder" button, then quits. Fill in the same keys as `.env.local.example` (see [`INTEGRATIONS.md`](../INTEGRATIONS.md)) and relaunch.

## Logs

Server logs are written to `<userData>/logs/sky-server.log` (same base path as above, e.g. `~/Library/Application Support/Sky/logs/sky-server.log` on macOS).

## Install notes

**macOS (unsigned build):** Gatekeeper will block the app on first launch.

- Right-click the app → Open → Open, or
- Remove the quarantine attribute:

  ```bash
  xattr -dr com.apple.quarantine /Applications/Sky.app
  ```

**Windows (unsigned build):** SmartScreen will warn about an unrecognized app.

- Click "More info" → "Run anyway"

## CI builds

`.github/workflows/desktop.yml` builds both platforms:

- **Manual:** trigger via `workflow_dispatch` from the Actions tab
- **Tagged release:** push a tag matching `v*` (e.g. `v1.0.0`) to build and attach artifacts to a GitHub Release

The macOS build runs on `macos-26` (Xcode 26 preinstalled), needed for the adaptive icon's `actool` step.

Artifacts are unsigned, same as local builds.
