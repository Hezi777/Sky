# Sky — Plan

## Overview

Single-page personal dashboard. Opens every morning, shows live data across all services. No backend DB, no auth flows for end users, no multi-tenancy. Just env vars and Next.js API routes.

---

## Design System

Reference: Aura dashboard (Image 2) — clean white, minimal icon sidebar, generous card spacing.
Greeting: iMessage-style bubble card at the top.

| Token         | Value                        |
| ------------- | ---------------------------- |
| Primary blue  | `#2563EB`                    |
| Bg light      | `#F8FAFC`                    |
| Bg dark       | `#0B1220`                    |
| Card bg light | `#FFFFFF`                    |
| Card bg dark  | `#111827`                    |
| Border        | `#E2E8F0` / `#1F2937` (dark) |
| Text primary  | `#0F172A` / `#F1F5F9` (dark) |
| Text muted    | `#64748B` / `#94A3B8` (dark) |
| Radius        | `rounded-2xl` (cards)        |
| Font          | Geist (Next.js default)      |

Layout: left icon sidebar (48px wide, dark) + main content area. No text labels in sidebar. Active indicator = blue dot or blue fill icon.

Icons: `react-icons/si` for brand logos. `lucide-react` for UI icons (Bell, Settings, Moon, etc.).

---

## Layout Grid

```
[Sidebar 48px] | [Main content — 3 col grid on ≥1280px, 2 col on ≥768px, 1 col mobile]
               |
               | [Greeting card — full width, hero]
               | [Calendar] [TickTick] [Spotify]
               | [GitHub heatmap — full width]
               | [IBKR] [Notion Projects] [Notion Next Task]
               | [Resource Quick-Add — full width strip]
```

---

## Widget Specs

### 1. Greeting Card (full width hero)

- iMessage-style: white bubble with tail, blue gradient background behind it
- Content: "Good morning, Hen 👋" + AI-generated one-liner summarizing today (calendar events + TickTick tasks)
- AI model: Groq `llama-3.1-8b-instant` - fast, free, small prompt
- Prompt: "In one short friendly sentence, summarize Hen's day: he has [N] calendar events and [N] tasks due today including [titles]. Keep it under 20 words."
- Refreshes once on load. Cache with SWR `revalidateOnFocus: false`.
- Right side: date + time (live clock with `useEffect`)

### 2. Google Calendar

- Source: Google Calendar API v3
- Auth: OAuth 2.0 — one-time setup, refresh token stored in `.env.local`
- Endpoint: `GET /calendars/primary/events` with `timeMin=now`, `maxResults=5`, `orderBy=startTime`, `singleEvents=true`
- Display: next 5 events. Each shows: colored dot (from event `colorId`), title, time (relative: "in 2h" or "Tomorrow 10:00"), and optional location icon if location field is set.
- Empty state: "No upcoming events"

### 3. TickTick — Today's Tasks

- Source: TickTick OAuth 2.0 API (`https://api.ticktick.com/api/v2`)
- Auth: OAuth 2.0 PKCE — redirect flow on first run, refresh token in `.env.local`
- Endpoint: `GET /api/v2/batch/check/0` (returns full state including tasks)
- Filter: tasks where `dueDate` = today OR `startDate` = today, `status = 0` (incomplete)
- Task attributes to display: title, priority badge (None/Low/Medium/High mapped from 0/1/3/5), dueDate time if not all-day, tags as small chips, subtask count from `items.length`
- Priority color: None=gray, Low=blue, Medium=yellow, High=red
- Sort: priority desc, then dueDate asc

### 4. Spotify

- Source: Spotify Web API
- Auth: OAuth 2.0 PKCE — one-time login, refresh token in `.env.local`
- Endpoints:
  - `GET /me/player/currently-playing` — active track
  - `GET /me/player/recently-played?limit=4` — fallback + recent list
- Display top half: album art (rounded-xl, 56px), track title, artist, progress bar if playing. "Currently playing" animated equalizer bars icon when active.
- Display bottom: 4 recent tracks as small rows (art thumbnail 32px, title, artist)
- Brand icon: `SiSpotify` green `#1DB954`

### 5. GitHub

Two-part widget.

**Part A — Recent Repos** (top half):

- Source: GitHub REST API v3
- Auth: Personal Access Token (PAT) in `.env.local` — no OAuth needed
- Endpoint: `GET /user/repos?sort=pushed&per_page=4`
- Display: repo name, description (truncated 60 chars), language tag, last pushed relative time, star count

**Part B — Contribution Heatmap** (bottom half):

- Source: GitHub GraphQL API
- Query: `contributionsCollection` for last 52 weeks
- Display: standard heatmap grid (7 rows × 52 cols). Colors: `#161b22` (0), `#0e4429`, `#006d32`, `#26a641`, `#39d353` (max) — GitHub green scale
- Build with plain SVG `<rect>` elements. No lib needed.
- Tooltip on hover: "N contributions on [date]"

### 6. IBKR — Portfolio

Long-term investor view. No day-trading metrics.

- Source: IBKR Client Portal Web API (runs locally on `https://localhost:5000`)
- Auth: IBKR Gateway must be running locally. Token auto-manages via cookie session.
- Endpoints:
  - `GET /v1/api/portfolio/accounts` → get accountId
  - `GET /v1/api/portfolio/{accountId}/summary` → net liquidation, day P&L, unrealized P&L
  - `GET /v1/api/portfolio/{accountId}/positions/0` → individual positions
- Display:
  - Top row: Total value (large number), Day P&L with +/- color, Total unrealized P&L %
  - Center: Donut chart (Recharts) showing allocation by ticker — SPY/QQQ/NVDA/IWM with % and $ labels
  - Bottom: Position list — ticker, shares, avg cost, current price, P&L %
- Color coding: green if P&L positive, red if negative
- Note in widget footer: "Requires IBKR Gateway running on localhost:5000"

### 7. Notion — Active Projects

- Source: Notion API
- Auth: Notion Integration token in `.env.local`. Integration must be shared with the Portfolio Tracker database.
- Database ID: `05903059-6ee7-4f28-b97e-808030c47b00`
- Filter: `Stage = "In progress" OR Stage = "Finishing"`, exclude `Type = "Idea"`
- Display per project: Project name (title), Stage badge (colored per option), Type badge, Stack (small gray text), Next Action (shown as a "→ next step" line in muted text)
- Max 4 rows. "See all in Notion" link at bottom.

### 8. Notion — Next Task

- Same database, same integration token
- Filter: `Stage = "In progress"`, sort by `createdTime ASC` (oldest active first = most urgent)
- Display: single project card, large "Next Action" text as the focus, project name as subtitle, Stage + Type badges
- This is the "what are you working on right now" widget — keep it prominent

### 9. Resource Quick-Add (full width strip)

- UI: single text input "Paste a URL..." + Add button
- On submit: POST to `/api/ai/resource` with `{ url }`
- Server-side route:
  1. Fetch URL metadata (title, description via `og:title`, `og:description`, and full page text if needed)
  2. Call Groq `llama-3.3-70b-versatile` with prompt: "Given this URL and its content, return ONLY valid JSON with these fields: Name (string), Description (max 120 chars), Category (one of: Claude Code, UI Components, Design Inspo, AI Tools, Dev Infrastructure, SaaS/Biz, Learning, BI/Data, Tools, GitHub), Status ('Saved'). URL: [url]. Content: [og tags + description]"
  3. Parse JSON response
  4. POST to Notion API to create page in Resources DB (`31f86eb0-7b69-80e2-9ec4-000b45acce82`)
- Success: green toast "Added to Notion Resources". Error: red toast with message.
- Notion Resources schema: Name (title), URL (url), Description (text), Status (select), Category (multi_select)

---

## Service Integration Strategy

| Service         | Method              | Auth Type           | Complexity |
| --------------- | ------------------- | ------------------- | ---------- |
| Google Calendar | Google Calendar API | OAuth 2.0 + refresh | Medium     |
| TickTick        | TickTick OAuth API  | OAuth 2.0 PKCE      | Medium     |
| Spotify         | Spotify Web API     | OAuth 2.0 PKCE      | Easy       |
| GitHub          | REST + GraphQL API  | PAT token           | Easy       |
| Notion          | Notion API          | Integration token   | Easy       |
| IBKR            | Client Portal API   | Gateway session     | Medium     |
| Groq (AI)       | Groq API            | API key             | Easy       |

---

## AI Integration (Groq)

Free tier at `api.groq.com/openai/v1`. Use OpenAI-compatible SDK (`groq` npm package or `openai` with baseURL override).

| Use case         | Model                     | Est. tokens |
| ---------------- | ------------------------- | ----------- |
| Greeting summary | `llama-3.1-8b-instant`    | ~150 in/out |
| Resource analyze | `llama-3.3-70b-versatile` | ~500 in/out |

---

## Environment Variables

```bash
# Google Calendar
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=
GOOGLE_REFRESH_TOKEN=

# TickTick
TICKTICK_CLIENT_ID=
TICKTICK_CLIENT_SECRET=
TICKTICK_REFRESH_TOKEN=

# Spotify
SPOTIFY_CLIENT_ID=
SPOTIFY_CLIENT_SECRET=
SPOTIFY_REFRESH_TOKEN=

# GitHub
GITHUB_PAT=

# Notion
NOTION_TOKEN=
NOTION_RESOURCES_DB_ID=31f86eb0-7b69-80e2-9ec4-000b45acce82
NOTION_PROJECTS_DB_ID=05903059-6ee7-4f28-b97e-808030c47b00

# IBKR (local gateway)
IBKR_GATEWAY_URL=https://localhost:5000

# AI
GROQ_API_KEY=
```

---

## Build Order

1. Scaffold Next.js 15 + shadcn init + Tailwind config with design tokens
2. Layout shell: sidebar + main grid
3. Greeting card (static text first, wire AI last)
4. Notion widgets (easiest auth — just a token)
5. GitHub widgets (PAT, no OAuth)
6. Spotify widget (OAuth flow)
7. Google Calendar widget (OAuth flow)
8. TickTick widget (OAuth flow)
9. IBKR widget (requires gateway setup)
10. Resource Quick-Add + Groq wiring
11. Greeting AI wiring
12. Dark mode polish
13. Deploy to Vercel (set all env vars in Vercel dashboard)
