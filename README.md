<h1 align="center"><b>Lesikum</b></h1>

<p align="center">A personal read-only dashboard that aggregates Google Calendar, Notion, Spotify, GitHub, TickTick, and Interactive Brokers into one interface.</p>

<p align="center">
  <img src="https://img.shields.io/badge/Next.js-black?style=for-the-badge&logo=next.js&logoColor=white" alt="Next.js" />
  <img src="https://img.shields.io/badge/TypeScript-3178C6?style=for-the-badge&logo=typescript&logoColor=white" alt="TypeScript" />
  <img src="https://img.shields.io/badge/Supabase-3FCF8E?style=for-the-badge&logo=supabase&logoColor=white" alt="Supabase" />
  <img src="https://img.shields.io/badge/Tailwind_CSS-06B6D4?style=for-the-badge&logo=tailwindcss&logoColor=white" alt="Tailwind CSS" />
  <img src="https://img.shields.io/badge/private-repo-lightgrey?style=for-the-badge" alt="Private" />
</p>

<p align="center">
  <a href="#about">About</a> |
  <a href="#integrations">Integrations</a> |
  <a href="#tech-stack">Tech Stack</a> |
  <a href="#getting-started">Getting Started</a> |
  <a href="#contributing">Contributing</a>
</p>

---

## About

Lesikum is a single-user personal dashboard built to replace opening six separate apps just to get a read on the day. It pulls data from external services on a schedule, caches the results in Supabase, and serves a fast, read-only UI - the page never calls an external API at render time. The project is currently in active development: the application shell is built and the database is wired, but the individual service integrations are not yet complete.

## Integrations

| Service | Data surfaced | Status |
|---|---|---|
| Spotify | Last played track and most recent playlist | In progress |
| Notion | Resources DB quick-add with AI-generated description (Groq) | In progress |
| Google Calendar | Today's events in time order | In progress |
| GitHub | Latest Actions run status and open PR count per active repo | In progress |
| TickTick | Today's incomplete tasks | In progress |
| Fair (Meitav fund 5140785) | Current fund value, total contributed, gain/loss, DCA settings | In progress |
| Interactive Brokers | Portfolio total value and daily change via Flex Web Service | In progress |

All data is fetched by scheduled Vercel cron jobs and written to Supabase. The UI reads from the cache only.

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Next.js 16.2 (App Router, Turbopack) |
| Language | TypeScript 5 |
| UI library | React 19 |
| Component library | shadcn/ui (Radix UI primitives) |
| Styling | Tailwind CSS 4 (CSS-first configuration) |
| Database / cache | Supabase (Postgres + @supabase/ssr 0.10) |
| Linter / formatter | Biome 2 |
| Deployment | Vercel (cron jobs for scheduled data fetching) |

## Getting Started

### Prerequisites

- Node.js 20.9 or later
- pnpm
- A Supabase project with the schema from `supabase/migrations/0001_init.sql` applied
- API credentials for each service you want to enable (see `docs/agent/integrations.md`)

### 1. Clone

```bash
git clone <repo-url>
cd Lesikum
```

### 2. Install dependencies

```bash
pnpm install
```

### 3. Configure environment variables

Copy the example and fill in your values:

```bash
cp .env.example .env.local
```

Required variables:

```
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=
SUPABASE_SECRET_KEY=
```

Each integration adds its own variables (OAuth client IDs, secrets, API tokens). See `docs/agent/integrations.md` and `docs/agent/running-locally.md` for the full list and OAuth setup instructions.

### 4. Run locally

```bash
pnpm dev
```

Open [http://localhost:3000](http://localhost:3000). The dashboard shell renders immediately; widgets show skeleton content until integrations are wired and cron jobs have run at least once.

### 5. Verify before committing

```bash
pnpm verify
```

This runs `tsc` and `biome check`. Both must pass clean.

## Contributing

This is a personal project. Pull requests are not expected and the repo is private. If you have found it and want to adapt it for your own use, the code is yours to learn from.

## License

Unlicensed - private personal project.
