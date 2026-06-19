# Sky Native — Build Spec

Native SwiftUI client for **Sky**, targeting **macOS 26 + iOS 26** (Liquid Glass era).
Single-user personal dashboard for Hen. Built free (Personal Team signing).

## Architecture

- **One repo, two clients.** `/` = existing Next.js + Electron app (the **backend**). `/native` = this SwiftUI app.
- **Backend reuse.** The SwiftUI app calls the existing `app/api/*` route handlers — no integration rewrite, secrets stay server-side.
  - Dev base URL: `http://localhost:3000` (run `npm run dev` in repo root).
  - Later: deploy the Next.js app to Vercel (free) → set base URL to the deployed origin so iPhone works away from home.
  - Auth: single-user, local. Add a `Authorization: Bearer <token>` header later if the backend is deployed publicly. For localhost dev, no auth.
- **No database, no client-side secrets.** Same rules as the web app.

## Free Native Constraints

- Personal Team signing (`CODE_SIGN_STYLE: Automatic`, no paid program).
- Blocked without $99: HealthKit, App Groups (→ no home-screen WidgetKit), WeatherKit, Push.
- Therefore: weather via **Open-Meteo** (no key), no Apple Health widget yet, no iOS home-screen widget yet. All in-app widgets work free.
- iPhone install: 7-day re-sign (or SideStore). macOS: local build runs freely.

## Structure (`native/`)

```
native/
  project.yml                 # XcodeGen spec (canonical project definition)
  Sky/
    SkyApp.swift              # @main app entry (multiplatform)
    DesignSystem/             # Color, Glass, Typography, Spacing, cloud assets
    Networking/               # APIClient, Endpoints, decoding
    Models/                   # Codable structs mirroring lib/types.ts
    Stores/                   # @Observable app state, widget-visibility, settings
    Views/
      Dashboard/              # grid, hero/greeting zone, bottom bar
      Widgets/                # one file per card
      Settings/               # widget picker (eye toggles) + prefs, Liquid Glass
      Charts/                 # reusable Apple-style Swift Charts components
    Resources/
      Assets.xcassets         # cloud-*.png, colors
  docs/                       # research cheatsheets (build-runbook, swiftui-2026)
```

## Backend API surface (mirror in Models/)

| Endpoint | Method | Response type |
|---|---|---|
| `/api/ai/greeting` | POST `{events,tasks,commits,portfolioChange,nowPlaying,mood}` | `GreetingResponse { message }` |
| `/api/calendar` | GET | `CalendarEvent[]` |
| `/api/ticktick` | GET | `TickTickTask[]` |
| `/api/ticktick/complete` | POST `{id}` | `{ ok }` |
| `/api/github` | GET | `GithubResponse { repos, contributions, totalContributions }` |
| `/api/spotify` | GET | `SpotifyResponse { nowPlaying, recent }` |
| `/api/ibkr` | GET | `IbkrResponse { source, asOf, summary, positions }` |
| `/api/notion/projects` | GET | `NotionProject[]` |
| `/api/notion/nexttask` | GET | `NotionNextTask` |
| `/api/fair` | GET | `FairPrice` |

Exact field shapes: see repo `lib/types.ts` (mirrored 1:1 in `Models/`).

## Widgets

**Existing (port to SwiftUI):**
- Greeting + cloud character (cloud state by time/activity, AI message)
- Calendar (Google) · Tasks (TickTick, with complete) · GitHub (repos + contribution heatmap)
- Spotify (now playing + recent) · IBKR (portfolio donut + positions) · Fair (DCA tracker)

**New (this build):**
- **Reading tracker** — Notion reading DB (in "Areas" page; find DB id via Notion MCP). New backend route `/api/notion/reading`.
- **Trip countdown** — customizable; default Thailand, target **2026-12-20**. Local config, multiple trips.
- **Stocks** — user-chosen tickers, daily % change. **Finnhub** free (60/min). New route `/api/stocks?symbols=`.
- **Weather** — current location via **CoreLocation**, data via **Open-Meteo** (no key). Native (not backend).
- **Daily quote** — **ZenQuotes** (free, attribution). New route `/api/quote` or direct.
- **Strava** — free user OAuth, recent run/distance. New route `/api/strava`. (Deferred if OAuth setup needed.)

## Widget visibility

- A **widget picker** in Settings: list every widget with an **eye toggle** (show/hide) and drag-to-reorder.
- Persisted in `@AppStorage`/`UserDefaults`. Existing widgets default ON.
- Use Liquid Glass surfaces for the settings pane.

## Design direction

- **Liquid Glass** everywhere it fits: toolbar, settings, segmented controls, floating bars, prominent buttons.
- **Apple-native charts** (Swift Charts) — clean, minimal grids, gradient area fills, rounded bars, donut via `SectorMark`, rolling numbers (`.contentTransition(.numericText())`). Match the Harvee / Apple Health aesthetic.
- Light + dark parity. Cohesive, calm, native macOS feel.
- Cloud character art reused from `/public/assets/cloud` (copy into Assets.xcassets).

## Build (see docs/build-runbook.md for exact commands)

```bash
cd native && xcodegen generate
xcodebuild -scheme Sky -destination 'platform=macOS' build | xcbeautify
```
