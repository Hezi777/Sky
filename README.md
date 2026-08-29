<p align="center">
  <img src="./native/Sky/Assets.xcassets/cloud-hero.imageset/cloud-hero.png" width="120" height="120" alt="Sky cloud character" />
</p>

<h1 align="center"><b>Sky - Sof Kol Yom</b></h1>

<p align="center">A single-user personal dashboard with a Next.js web backend, Electron desktop shell, and native SwiftUI macOS/iOS client.</p>

<p align="center">
  <img src="https://img.shields.io/badge/Next.js-black?style=for-the-badge&logo=next.js&logoColor=white" alt="Next.js" />
  <img src="https://img.shields.io/badge/React_19-149ECA?style=for-the-badge&logo=react&logoColor=white" alt="React" />
  <img src="https://img.shields.io/badge/TypeScript-3178C6?style=for-the-badge&logo=typescript&logoColor=white" alt="TypeScript" />
  <img src="https://img.shields.io/badge/Tailwind_v4-06B6D4?style=for-the-badge&logo=tailwindcss&logoColor=white" alt="Tailwind CSS" />
  <img src="https://img.shields.io/badge/Groq-F55036?style=for-the-badge&logo=groq&logoColor=white" alt="Groq" />
  <img src="https://img.shields.io/badge/private-repo-lightgrey?style=for-the-badge" alt="Private" />
</p>

<p align="center">
  <a href="#about">About</a> |
  <a href="#dashboard">Dashboard</a> |
  <a href="#screenshots">Screenshots</a> |
  <a href="#tech-stack">Tech Stack</a> |
  <a href="#getting-started">Getting Started</a> |
  <a href="#connecting-services">Connecting Services</a>
</p>

---

## About

Sky is a personal dashboard that replaces opening six apps every morning to check on the day. It is single-user (no auth, no multi-tenancy) and always live-fetched: there is no database and no cache.

The repo has three app surfaces:

- `app/`, `components/`, `lib/`: Next.js web dashboard and API route backend.
- `electron/`: Electron shell that packages the web app.
- `native/`: SwiftUI macOS/iOS client generated with XcodeGen and backed by the same Next.js API routes.

Secrets stay in `.env.local` and never reach client code. External service calls go through `app/api/*` route handlers; the native app reuses those routes instead of duplicating privileged integrations.

Each widget fetches independently with SWR, shows its own skeleton while loading, and falls back to a local error state if its service is not connected, so one missing connector does not break the rest of the page.

## Dashboard

The page is a bento grid where each widget is sized by importance and content shape. It has a time-based greeting, a live clock, and a dark mode.

| Widget                | Data surfaced                                                       | Status        |
| --------------------- | ------------------------------------------------------------------ | ------------- |
| Greeting (Groq AI)    | One-line AI summary of the day                                     | Live          |
| GitHub                | Recent repos and contribution heatmap                             | Live          |
| Notion - Projects     | Active projects from the Portfolio Tracker DB                     | Live          |
| Notion - Next Task    | The most urgent in-progress project                              | Live          |
| Resource Quick-Add    | Paste a URL, Groq classifies it, saved to the Notion Resources DB | Live          |
| Spotify               | Now playing and recently played                                   | Needs OAuth   |
| Google Calendar       | Next 5 events                                                     | Needs OAuth   |
| TickTick              | Today's incomplete tasks                                          | Needs OAuth   |
| Interactive Brokers   | Portfolio value, allocation donut, positions via official Flex snapshots or local IBKR Gateway | Needs setup   |
| Fair (Maya / TASE)    | Israeli mutual fund unit price, personal contributions, and P&L tracker                        | Live (no auth) |

See [`docs/integrations.md`](./docs/integrations.md) for auth setup per service.

## Screenshots

The dashboard shifts palette through the day.

| Morning |
|---|
| ![Dashboard, morning](docs/screenshots/dashboard-morning.png) |

| Afternoon | Evening |
|---|---|
| ![Dashboard, afternoon](docs/screenshots/dashboard-afternoon.png) | ![Dashboard, evening](docs/screenshots/dashboard-evening.png) |

## Tech Stack

| Layer             | Technology                                          |
| ----------------- | --------------------------------------------------- |
| Web framework     | Next.js (App Router, Turbopack)                     |
| Language          | TypeScript 5 (strict)                               |
| UI library        | React 19                                            |
| Components        | shadcn/ui Nova (Base UI primitives), lucide + react-icons |
| Styling           | Tailwind CSS v4 (CSS-first `@theme` tokens)         |
| Data fetching     | SWR (per-widget, client-side)                       |
| Web charts        | Recharts                                            |
| Native app        | SwiftUI, Swift 6, XcodeGen                          |
| Native charts     | Swift Charts                                        |
| AI                | Groq (`llama-3.1-8b-instant`, `llama-3.3-70b`)      |
| Linter            | ESLint 9 (`eslint-config-next`)                     |
| Brokerage data    | Official IBKR Flex Web Service + optional Client Portal Gateway |
| Deployment        | Vercel                                              |

No database. No background jobs. Data is fetched on demand by the API routes.

## Getting Started

### Prerequisites

- Node.js 20+
- API credentials for whichever services you want to enable (see [Connecting Services](#connecting-services))

### 1. Install

```bash
npm install
```

### 2. Configure environment

```bash
cp .env.local.example .env.local
```

Fill in the credentials for the services you want. `.env.local` is gitignored. GitHub, Notion, and Groq only need their token or key; the OAuth services need a one-time flow (below).

### 3. Run

```bash
npm run dev      # dev server at http://localhost:3000
npm run build    # production build
npm run lint     # eslint
```

The shell renders right away. Each widget loads its own data, and any service you have not connected shows its error state without affecting the others.

## Repo Structure

```text
app/                 Next.js App Router pages and API routes
components/          Web dashboard components and widgets
lib/                 Web/API integration clients, shared types, Groq helpers
electron/            Electron source
electron-dist/       Generated Electron output (ignored)
native/
  project.yml        XcodeGen source of truth
  Sky/               SwiftUI source, models, stores, assets, widgets
  docs/              Native build and SwiftUI notes
  Sky.xcodeproj/     Generated by XcodeGen (ignored)
  .build*/           Xcode build output (ignored)
public/              Web/Electron static assets, including .icon source bundle
assets/              Release artwork, DMG backgrounds, source assets
release/             Generated releases (ignored): electron/<version>/, native/<version>/
scripts/             Local setup/build scripts
```

`native/project.yml` is canonical for the Xcode project. Regenerate `native/Sky.xcodeproj/` instead of editing it by hand.

## Connecting Services

Full details are in [`docs/integrations.md`](./docs/integrations.md). Quick reference:

- **GitHub**: set `GITHUB_PAT` and `GITHUB_USERNAME`. Works immediately.
- **Notion**: create an integration, share the Portfolio Tracker and Resources databases with it (DB, then ... menu, then Connections), then set `NOTION_TOKEN` and the two DB IDs.
- **Groq**: set `GROQ_API_KEY` (free tier at console.groq.com).
- **Spotify, Google Calendar, TickTick**: run the one-time OAuth helper from the project root to get a refresh token:

  ```bash
  node scripts/get-spotify-token.mjs
  node scripts/get-google-token.mjs
  node scripts/get-ticktick-token.mjs
  ```

  Each one prints the redirect URI to register and the line to paste into `.env.local`. See [`scripts/README.md`](./scripts/README.md).
- **Interactive Brokers**: for persistent read-only portfolio snapshots, enable IBKR Flex Web Service, create an Activity Flex Query with Open Positions and Net Asset Value, then set `IBKR_DATA_SOURCE=flex`, `IBKR_FLEX_TOKEN`, and `IBKR_FLEX_QUERY_ID`. For live gateway data, run `npm run ibkr:setup`, `npm run ibkr:start`, then log in at `https://localhost:5001`.

## Desktop app

Sky is also packaged as a desktop app (Electron) for macOS and Windows. Build locally with `npm run electron:build` (output in `release/electron/<version>/`), or grab a build from CI via `workflow_dispatch` or a `v*` tag release. See [`docs/desktop.md`](./docs/desktop.md) for setup, config location, logs, and install notes (Gatekeeper / SmartScreen).

## Native app

The SwiftUI client lives in `native/` and targets macOS/iOS. It uses the root Next.js API routes as its backend, so run the web server locally when testing live integrations:

```bash
npm run dev
npm run native:generate
npm run native:build
npm run native:dist
```

`native:build` creates `native/.build/Build/Products/Debug/Sky.app`. `native:dist` packages it as `release/native/<version>/Sky-native.dmg` using `assets/dmg/native-background.png` as the DMG background. Native build output stays under ignored Xcode build folders. The source files to edit are under `native/Sky/`.

## License

Unlicensed, private personal project.
