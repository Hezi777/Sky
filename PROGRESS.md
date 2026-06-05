# Sky - Progress

> Living checklist. Check off as you go. Don't delete items - use ~~strikethrough~~ for removed scope.

---

## Phase 1 - Scaffold

- [x] Scaffold with `create-next-app@latest` - installed **Next.js 16 + React 19 + Tailwind v4** (newer than the planned v15; App Router unchanged)
- [x] Install deps: `shadcn@latest init` (Nova preset), `swr`, `recharts`, `react-icons`, `lucide-react`, `next-themes`, `groq-sdk` (not `groq` - that's Sanity's package), `@notionhq/client`
- [x] Design tokens - Tailwind v4 is CSS-first, so tokens live in `app/globals.css` (`@theme`/`:root`/`.dark`), not `tailwind.config.ts`
- [x] Add `.env.local.example` with all variable names (renamed from `env.local.example`; real secrets moved to gitignored `.env.local`)
- [x] Create `lib/types.ts` - typed interfaces for all API responses
- [x] Create layout shell: sidebar (icon nav, dark) + main area
- [x] Add dark mode toggle (`next-themes` ThemeProvider in layout)
- [x] Add header: time-based greeting + live clock + dark toggle
- [~] Deploy to Vercel - **needs your Vercel login** (can't authenticate from here). Local `npm run build` passes as the build-confirmation proxy.

---

## Phase 2 - Easy Widgets (no OAuth)

### Notion

- [x] Create Notion integration at notion.so/my-integrations (bot "Sky Dashboard", token valid)
- [ ] **Share Portfolio Tracker DB with integration** ← YOUR ACTION (DB ••• → Connections → Sky Dashboard). Blocks live data.
- [ ] **Share Resources DB with integration** ← YOUR ACTION (needed for Resource Quick-Add write)
- [x] Add `NOTION_TOKEN` to `.env.local`
- [x] Build `/api/notion/projects` route (uses v5 dataSources API; live 404 until DB shared)
- [x] Build `/api/notion/nexttask` route
- [x] Build `ActiveProjects` widget component
- [x] Build `NextTask` widget component

### GitHub - ✅ verified live (4 repos, 378 contributions)

- [x] Generate PAT (set in `.env.local`, confirmed working as Hezi777)
- [x] Add `GITHUB_PAT` to `.env.local`
- [x] Build `/api/github` route (REST repos + GraphQL contributions)
- [x] Build `GithubRepos` component (recent 4 repos)
- [x] Build `GithubHeatmap` component (SVG contribution grid)

---

## Phase 3 - OAuth Widgets

> Phase 3 widgets are all BUILT but UNVERIFIED - refresh tokens are empty in `.env.local`.
> Each needs a one-time browser OAuth flow to obtain its refresh token. Until then the widget shows its error state.

### Spotify

- [x] Spotify app created (CLIENT_ID/SECRET set)
- [ ] **Run one-time OAuth flow to get refresh token** ← YOUR ACTION (`SPOTIFY_REFRESH_TOKEN` empty)
- [~] `SPOTIFY_CLIENT_ID`, `SPOTIFY_CLIENT_SECRET` set; `SPOTIFY_REFRESH_TOKEN` empty
- [x] Build `/api/spotify` route (currently playing + recently played)
- [x] Build `SpotifyWidget` component

### Google Calendar

- [x] Google Cloud project + OAuth client (CLIENT_ID/SECRET set)
- [ ] **Run one-time OAuth flow to get refresh token** ← YOUR ACTION (`GOOGLE_REFRESH_TOKEN` empty)
- [~] `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET` set; `GOOGLE_REFRESH_TOKEN` empty
- [x] Build `/api/calendar` route (next 5 events)
- [x] Build `CalendarWidget` component

### TickTick

- [x] TickTick app (CLIENT_ID/SECRET set)
- [ ] **Run one-time OAuth flow to get refresh token** ← YOUR ACTION (`TICKTICK_REFRESH_TOKEN` empty)
- [x] Build `/api/ticktick` route (today's tasks filtered by date) - ⚠️ uses undocumented v2 endpoint, may need adjustment once token exists
- [x] Build `TickTickWidget` component (title, priority badge, tags, subtask count)

---

## Phase 4 - IBKR

- [ ] **Download and install IBKR Client Portal Gateway (Java)** ← YOUR ACTION
- [ ] **Confirm gateway runs on `https://localhost:5000`** ← YOUR ACTION (route uses undici dispatcher to accept the self-signed cert)
- [x] Add `IBKR_GATEWAY_URL` to `.env.local`
- [x] Build `/api/ibkr` route (summary + positions) - BUILT, unverified until gateway runs
- [x] Build `IBKRWidget` component:
  - [x] Total value + day P&L header
  - [x] Recharts Donut chart (allocation by ticker)
  - [x] Position list table

---

## Phase 5 - AI Features

### Groq - ✅ verified live

- [x] Groq API key (set in `.env.local`, confirmed working)
- [x] Add `GROQ_API_KEY` to `.env.local`
- [x] Build `lib/groq.ts` with typed helper functions (llama-3.1-8b-instant + llama-3.3-70b-versatile)

### Resource Quick-Add

- [x] Build `/api/ai/resource` route:
  - [x] Fetch URL og-tags + metadata (verified)
  - [x] Call Groq for JSON classification (verified)
  - [~] POST to Notion Resources DB - blocked until Resources DB is shared with the integration
- [x] Build `ResourceQuickAdd` component (input + submit + toast feedback)

### Greeting AI - ✅ verified live

- [x] Build `/api/ai/greeting` route (returns one sentence; verified with real Groq output)
- [x] Wire into `GreetingCard` component (currently passes empty events/tasks - wire real Calendar+TickTick data once those tokens exist)

---

## Phase 6 - Polish & Deploy

- [ ] Skeleton loaders for all widgets (use shadcn `Skeleton`)
- [ ] Error states for all widgets
- [ ] Dark mode - verify all widgets look correct
- [ ] Mobile layout (single column, sidebar collapses to bottom bar)
- [ ] Add all env vars to Vercel dashboard
- [ ] Final deploy and smoke test all widgets

---

## Parking Lot (nice-to-have, post-v1)

- [ ] TickTick: complete task from dashboard (checkbox click → API call)
- [ ] Calendar: quick-add event
- [ ] Spotify: open in app deep link on track click
- [ ] IBKR: mini sparkline per position (30d price history)
- [ ] Notion Resources: list view of last 5 saved resources below the quick-add
- [ ] Finalize project name (currently "Sky")
