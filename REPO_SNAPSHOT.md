# Sky repository snapshot

Snapshot of the working tree on 2026-06-22. This describes the checked-out code, including existing uncommitted work; generated/local directories are called out separately.

## Stacks and app boundaries

| Surface | Stack | Role |
|---|---|---|
| Web + backend | TypeScript 5, Next.js 16.2.7 App Router, React 19.2.4, Tailwind CSS 4, SWR | Single-page dashboard plus all server-side `/api/*` integrations. |
| Electron desktop | TypeScript, Electron 39, electron-builder | Wraps the same Next.js app; production bundles the standalone Next server and launches it on localhost. macOS arm64 and Windows x64 are configured. |
| Native desktop/mobile | Swift 6, SwiftUI, Swift Charts, XcodeGen | Separate macOS 26/iOS 26 client. It normally calls the Next.js API backend; weather and daily quote call public APIs directly. |
| Tooling | Bash, JavaScript/MJS, Python | OAuth helpers, IBKR gateway control, screenshots, icons, and DMG packaging. |

This is one product with **three app surfaces and two application stacks**. Electron is not a separate frontend: it reuses the web app. The SwiftUI app is a separate frontend and shares API response contracts manually with TypeScript.

## Structure

```text
Sky/
├── app/
│   ├── api/{ai,calendar,fair,github,ibkr,notion,spotify,stocks,strava,ticktick}/
│   ├── layout.tsx
│   └── page.tsx
├── components/
│   ├── layout/
│   ├── ui/
│   └── widgets/
├── hooks/
├── lib/
│   └── __tests__/
├── electron/
├── native/
│   ├── Sky/{DesignSystem,Models,Networking,Stores,Views}/
│   ├── docs/
│   ├── project.yml
│   └── build-*.sh
├── scripts/
│   ├── ibkr/
│   └── icons/
├── public/
│   ├── Mac Icon.icon/
│   └── assets/{cloud,integrations,sky}/
├── assets/{dmg,icons,source}/
├── docs/screenshots/
├── .github/workflows/
├── package.json
├── next.config.ts
└── electron-builder.yml
```

| Top-level path | Purpose |
|---|---|
| `app/` | Next.js root page/layout and server route handlers. |
| `components/` | Web dashboard, settings, design primitives, and widgets. |
| `hooks/` | Client state hook for time-dependent cloud artwork. |
| `lib/` | Server integration clients, shared TypeScript response types, and utilities. |
| `electron/` | Electron main process, embedded-server launcher, first-run config, and menu. |
| `native/` | XcodeGen SwiftUI source, assets, native build scripts, and native-specific docs. |
| `scripts/` | OAuth token helpers, screenshot/icon utilities, IBKR tools, and Electron DMG scripts. |
| `public/` | Web/Electron runtime artwork and adaptive macOS icon source. |
| `assets/` | Release icons, DMG backgrounds, and ignored raw design sources. |
| `docs/` | Integration/desktop setup and checked-in dashboard screenshots. |
| `.github/` | Tagged/manual Electron builds for macOS and Windows. |
| `tools/` | Ignored local IBKR Client Portal Gateway installation and runtime data. |

Present but ignored/generated locally: `.next/`, `node_modules/`, `electron-dist/`, `release/`, `native/Sky.xcodeproj/`, `native/.build/`, `native/.build-ios/`, `native/.dmgvenv/`, `tools/ibkr/`, and raw `assets/source/`.

## Build, run, and test

Run root commands from `Sky/` unless noted.

| Target | Exact commands | Output / notes |
|---|---|---|
| Install | `npm install` (README) or deterministic `npm ci` (CI) | Node 20+ documented; CI uses Node 24. |
| Web dev | `npm run dev` | Next dev server at `http://localhost:3000`. |
| Web production | `npm run build` then `npm run start` | `next.config.ts` produces standalone output. |
| Web lint | `npm run lint` | Runs `eslint`. |
| Electron dev | `npm run electron:dev` | Compiles `electron/*.ts`, starts Next dev, then opens Electron. |
| Electron compile | `npm run electron:compile` | Writes generated JS to `electron-dist/`. |
| Electron release | `npm run electron:build` | Next build + Electron compile + electron-builder + `scripts/build-dmg.sh`; see packaging defect below. |
| Native project | `npm run native:generate` | Runs `xcodegen generate` in `native/`; `native/project.yml` is canonical. |
| Native macOS debug | `npm run native:build` | Regenerates then builds unsigned app at `native/.build/Build/Products/Debug/Sky.app`. Requires XcodeGen, Xcode, and `xcbeautify`. |
| Native macOS DMG | `npm run native:dist` | Debug build then `release/native/1.0.0/Sky-native.dmg`; first packaging can install `dmgbuild` from GitHub into `native/.dmgvenv`. |
| Native iOS simulator | `cd native && xcodegen generate`, then `xcodebuild -project Sky.xcodeproj -scheme Sky -configuration Debug -destination "platform=iOS Simulator,name=$DEVICE_NAME" -derivedDataPath .build build` | Simulator boot/install/launch commands are in `native/docs/build-runbook.md`. There is no root npm shortcut. |
| CI Electron | Manual dispatch or push a `v*` tag | `.github/workflows/desktop.yml` runs `npm ci`, web build, Electron compile, then `npx electron-builder --mac/--win --publish never`. |
| Tests | **No working command is configured.** | `lib/__tests__/cloud-state.test.ts` imports Vitest, but `vitest` is absent from `package.json` and there is no `test` script. No Swift test target exists in `native/project.yml`. |

Builds were not run for this snapshot because they write generated files and the requested inspection is read-only except for this document.

## Dependencies and integrations

### Key packages

- Framework/runtime: `next`, `react`, `react-dom`, `electron`.
- Fetching/state/UI: `swr`, `next-themes`, `framer-motion`, `recharts`, `sonner`, `date-fns`.
- Components/styling: `@base-ui/react`, shadcn-generated files under `components/ui/`, `tailwindcss`, `class-variance-authority`, `clsx`, `tailwind-merge`, `lucide-react`, `@iconify/react`, `react-icons`.
- Server integrations: `@notionhq/client`, `groq-sdk`, `fast-xml-parser`.
- Packaging/dev: `electron-builder`, `concurrently`, `wait-on`, `playwright`, TypeScript, ESLint.
- Declared but with no source import found: `liquid-glass-react`; `shadcn` is a CLI/dev authoring dependency in practice, not runtime code.

### External services and where they are called

| Service | Code path | Credentials/config |
|---|---|---|
| GitHub REST + GraphQL | `lib/github.ts` via `app/api/github/route.ts` | `GITHUB_PAT`, `GITHUB_USERNAME` |
| Google Calendar + OAuth | `lib/calendar.ts` via `app/api/calendar/route.ts`; token helper `scripts/get-google-token.mjs` | Google client ID/secret/refresh token |
| Spotify + OAuth | `lib/spotify.ts` via `app/api/spotify/route.ts`; helper `scripts/get-spotify-token.mjs` | Spotify client ID/secret/refresh token |
| TickTick MCP, private v2 session, or Open API v1 | `lib/ticktick.ts` via `app/api/ticktick/*`; helper `scripts/get-ticktick-token.mjs` | One of three auth paths documented in `.env.local.example` |
| Notion | `lib/notion.ts`, `app/api/notion/*`, `app/api/ai/resource/route.ts` | Token plus project/resource DB IDs; reading route instead hard-codes a data-source ID. |
| Groq chat completions | `lib/groq.ts` via `app/api/ai/greeting` and `/api/ai/resource` | `GROQ_API_KEY` |
| IBKR Client Portal Gateway | `lib/ibkr.ts`, `app/api/ibkr/*`, `scripts/ibkr/*`, ignored `tools/ibkr/` | Local gateway URL/account; browser login required. |
| IBKR Flex Web Service | `lib/ibkr-flex.ts` selected by `app/api/ibkr/route.ts` | Flex token/query ID/cache interval |
| TASE/Maya public fund API | `lib/fair.ts` via `app/api/fair/route.ts` | No key; fund ID is a query parameter. |
| Finnhub + Twelve Data | `app/api/stocks/route.ts` | Finnhub key required; Twelve Data optionally adds history. |
| Strava OAuth/API | `app/api/strava/route.ts` | Strava client ID/secret/refresh token. No matching token helper exists. |
| Open-Meteo | Direct from `native/Sky/Views/Widgets/WeatherWidget.swift` | No key; native location permission. |
| ZenQuotes | Direct from `native/Sky/Views/Widgets/QuoteWidget.swift` | No key. |
| jsDelivr memoji CDN | `lib/memojis.ts` | No key; currently disconnected from rendered UI. |

Secrets are server-side in `.env.local` for web and in Electron's user-data `.env` for packaged desktop. The native app supports `SKY_API_BASE_URL` and `SKY_API_TOKEN` Info.plist values, but no backend middleware or route code validates that bearer token.

## Entry points and execution flow

- Web: `app/page.tsx` → `components/dashboard.tsx`; global providers and desktop drag region start in `app/layout.tsx`.
- Backend: each `app/api/**/route.ts` exports a Next.js `GET`, `POST`, or `DELETE` handler; most delegate to `lib/*.ts`.
- Electron: package `main` is generated `electron-dist/main.js`, compiled from `electron/main.ts`. Dev loads `SKY_DEV_URL`; production uses `electron/server.ts` to fork bundled `.next/standalone/server.js`, then opens its localhost URL.
- Native: `native/Sky/SkyApp.swift` (`@main`) → `RootView.swift` → `Views/Dashboard/DashboardView.swift`. `Networking/APIClient.swift` defaults to `http://localhost:3000` and calls the same `/api/*` routes.
- CI: `.github/workflows/desktop.yml` starts on manual dispatch or a `v*` tag and publishes tagged artifacts to a GitHub Release.

## State of things

### Implemented

- The web dashboard renders calendar, TickTick, Spotify, IBKR, TASE fund, Notion projects/next task/resource capture, and GitHub widgets from `components/dashboard.tsx`.
- The native app has real implementations for all 12 cases in `native/Sky/Stores/WidgetKind.swift`, including native-only weather, quote, countdown, reading, stocks, and Strava widgets.
- Electron has first-run env setup, single-instance handling, external-link isolation, an embedded Next server, and versioned builder configuration under `electron/` and `electron-builder.yml`.

### Half-done or broken

- Native settings persist widget order (`native/Sky/Stores/DashboardConfig.swift`, `SettingsView.swift`), but `DashboardView.swift` renders fixed `rowAgenda/rowFinance/rowGitHub/rowSmall/rowSpotify` groups and never reads `visibleWidgets`; drag-to-reorder does not affect dashboard order.
- `app/api/notion/reading/route.ts` hard-codes `READING_DATA_SOURCE_ID`, so it is tied to one Notion workspace and is absent from `.env.local.example`.
- Electron packaging paths disagree: `electron-builder.yml` outputs `release/electron/${version}`, while `scripts/build-dmg.sh` searches `release/${version}/mac-arm64/Sky.app` and writes `release/${version}/...`. Therefore the final step of `npm run electron:build` cannot find the builder output as configured. The script also requires a globally available `create-dmg` not declared in `package.json`.
- CI calls electron-builder directly, whose mac targets are `dir` and `zip`, but `docs/desktop.md` says local/CI produces a DMG. CI's artifact glob allows a ZIP, so the job can succeed without a DMG.
- Testing is unfinished: one Vitest unit file exists, but there is no runner dependency or test script and no native tests.
- Current worktree is not clean: 21 tracked files are modified (primarily the native redesign plus `.env.local.example` and `docs/integrations.md`), and `DESIGN_SPEC.md` is untracked. This snapshot does not judge those changes as committed state.

### Duplicated, dead, or inconsistent

- `components/widgets/github-repos.tsx`, `components/widgets/greeting-card.tsx`, `components/glass-card.tsx`, and `components/memoji-picker.tsx` have no imports from the live web entry tree. `components/layout/header.tsx` and `sidebar.tsx` form a disconnected older layout; live `app/layout.tsx` uses `components/bottom-bar.tsx` instead.
- `native/Sky/Views/Widgets/WidgetPlaceholder.swift` still says widgets are temporary/coming soon, but no code references it and all widget cases have concrete implementations.
- Cloud/sky images are copied in both `public/assets/{cloud,sky}/` and `native/Sky/Assets.xcassets/`; the adaptive icon source is duplicated at `public/Mac Icon.icon/` and `native/Sky/AppIcon.icon/`. These copies are platform packaging inputs, but updates can drift.
- `package.json` says version `0.3.0`, while the root metadata in `package-lock.json` still says `0.1.1`; native release version is separately `1.0.0` in `native/project.yml`.
- `CLAUDE.md` says Next.js 15, while installed/declared Next.js is 16.2.7. It also bans inline styles, but Electron drag regions use inline `WebkitAppRegion` in `app/layout.tsx` and `components/bottom-bar.tsx`.
- `docs/desktop.md` links to nonexistent `../INTEGRATIONS.md`; the real file is `docs/integrations.md`.
- The web and native dashboards deliberately expose different widget sets. Stocks/Strava/reading backend routes are consumed only by native; web Notion project/resource widgets have no native equivalent. Contract parity is manual between `lib/types.ts` and `native/Sky/Models/*.swift`.

## Risks and unknowns

- There is no auth and API routes hold privileged personal-service access. Deploying the Next backend to a public Vercel origin would expose read/write routes unless protection is added; `SKY_API_TOKEN` currently protects only the client request header in name, not the server.
- Moving or deleting `app/api/` breaks all three surfaces. Changing JSON response shapes requires synchronized edits in route/lib TypeScript, web consumers, and `native/Sky/Models/*.swift`.
- Do not hand-edit or treat `native/Sky.xcodeproj/`, `.next/`, `electron-dist/`, build folders, releases, or `tools/ibkr/` as source; they are generated/ignored. `native/project.yml` is the Xcode source of truth.
- Deleting either copy of platform artwork can break web/native packaging even when another visually identical copy remains. DMG scripts also depend on exact paths under `assets/dmg/`.
- The native deployment settings require Xcode 26.5 and macOS/iOS 26; older Apple toolchains cannot build the target as configured.
- Electron releases are unsigned; Gatekeeper/SmartScreen warnings are expected. CI and local output behavior differ, and the current local DMG command is path-broken.
- Most integrations depend on live third-party schemas, OAuth refresh tokens, or a locally authenticated IBKR gateway. There are no integration tests or stored fixtures outside the screenshot mocks in `scripts/screenshot.mjs`.
- Existing build artifacts show the project has been built locally, but they do not prove the current uncommitted tree builds. Builds were intentionally not rerun for this read-only snapshot.

Sky is a private, single-user morning dashboard for personal schedule, tasks, media, projects, activity, and finances.
Its Next.js app is both the web UI and shared integration backend; Electron packages that same app.
A separate SwiftUI macOS/iOS client is substantial and uses the backend, with a few direct public-API widgets.
The core product is implemented, but tests, native reordering, public-backend protection, and Electron DMG packaging need work.
The working tree also contains an active native redesign, stale/disconnected UI code, duplicated assets, and documentation/version drift.
