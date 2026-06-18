---
name: recompile
description: Recompile and release the Sky Electron app with automatic version bumping. Use this skill whenever the user says to recompile, rebuild, re-release, ship, package, or cut a new version of the app. Also triggers on "build the app", "make a new release", "bump and build", "push a new version", "compile the electron app", or even just "ok ship it" or "build that" after making code changes.
---

# Recompile Sky Electron App

Full release cycle: analyze changes, bump version, build, report.

## Step 1: Verify Xcode

The macOS `.icon` bundle requires `actool` from full Xcode (not Command Line Tools).

```bash
xcode-select -p
```

If it returns `/Library/Developer/CommandLineTools`, stop and tell the user to run:
```
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

Do not proceed until `xcode-select -p` returns the Xcode path.

## Step 2: Determine Version Bump

Run `git diff HEAD --stat` and `git log --oneline -10` to understand what changed.

Classify automatically:

| Change type | Bump | Examples |
|---|---|---|
| Bug fixes, style tweaks, config, deps | **patch** | CSS fix, typo, icon swap, eslint config |
| New features, widgets, API routes, components | **minor** | New widget, new settings option, new integration |
| Breaking changes, major rewrites | **major** | Renamed all routes, switched frameworks |

Default to **patch** if unsure. If the user specified a bump type, use that. Tell the user what you chose and why in one sentence.

## Step 3: Bump Version

Read `package.json`, compute the new version, update only the `"version"` field with the Edit tool.

Do NOT use `npm version` — it creates unwanted git tags and commits.

## Step 4: Build

```bash
npm run electron:build
```

This runs: `next build && npm run electron:compile && electron-builder --publish never`

Output goes to `release/<new-version>/`.

### Common build failures

- **actool / Xcode error**: `xcode-select` not pointing to Xcode. See Step 1.
- **TypeScript errors**: fix the code and retry.
- **DMG background not filling**: `assets/dmg/background.png` must be exactly 720x402, `background@2x.png` must be exactly 1440x804. Dimensions must match `dmg.window` in `electron-builder.yml`.

## Step 5: Report

Tell the user:
- Version change (e.g. 0.1.1 → 0.1.2)
- Bump type and why
- Output path (DMG and zip locations in `release/<version>/`)
- Any build warnings
