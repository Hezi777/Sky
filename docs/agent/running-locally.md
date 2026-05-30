# Running locally

Requires Node 20.9+ (Next.js 16 minimum) and pnpm. TypeScript 5.1+.

## Scaffold
`pnpm create next-app@latest` - the default setup enables TypeScript, Tailwind, ESLint,
App Router, and Turbopack, and now also generates AGENTS.md + a CLAUDE.md that references
it. Replace/merge that generated CLAUDE.md with the hand-crafted one in this repo (do not
let /init or the generator overwrite ours - CLAUDE.md is hand-maintained).

## Tooling
- Tailwind 4: configure via @theme in your global CSS, NOT tailwind.config.js. Use the
  design tokens from design/DESIGN_BRIEF.md so design and code match.
- Biome 2: `pnpm dlx @biomejs/biome init`, then `biome migrate --write` if upgrading.
  Wire `biome check --write` into the Claude Code Stop hook so formatting/lint is
  deterministic and never spends model tokens.

## Env vars (.env.local - never commit)
- SUPABASE_URL
- SUPABASE_PUBLISHABLE_KEY  (sb_publishable_..., client-safe)
- SUPABASE_SECRET_KEY       (sb_secret_..., server-only - cron + writes)
- GROQ_API_KEY (for Notion AI descriptions - llama-3.1-8b-instant, free tier,
  you already have this key from the Whisper transcription project)
- SPOTIFY_CLIENT_ID, SPOTIFY_CLIENT_SECRET, SPOTIFY_REDIRECT_URI
- GOOGLE_CLIENT_ID, GOOGLE_CLIENT_SECRET, GOOGLE_REDIRECT_URI
- NOTION_TOKEN
- GITHUB_TOKEN (fine-grained, read-only, your repos)
- TICKTICK_CLIENT_ID, TICKTICK_CLIENT_SECRET
- FAIR_FUND_NUMBER=5140785   (the public fund to track; price fetch is best-effort)
- IBKR_FLEX_TOKEN, IBKR_FLEX_QUERY_ID   (Flex Web Service; preferred over the gateway)

## OAuth setup, per provider
For each OAuth provider (Spotify, Google, TickTick): register an app, set redirect URI to
your local + prod URLs, run the consent flow once, store the resulting refresh token in
oauth_tokens. The cron job uses the refresh token to mint access tokens.
GitHub uses a PAT (no flow). IBKR uses a Flex token (no OAuth). Fair uses no auth - it
just fetches a public fund price and reads my manually entered contributions.

## Running cron locally
Vercel cron only fires in deploy. Locally, hit the cron route handlers manually
(e.g. a `pnpm refresh:spotify` script that calls the same function) to populate the
cache while developing.

## First-run order
1. Create Supabase tables (see docs/ARCHITECTURE.md), enable RLS.
2. Set up the @supabase/ssr browser + server clients.
3. Wire ONE provider's OAuth + its cron route.
4. Manually trigger the refresh, confirm rows land in Supabase.
5. Build the widget that reads those rows.
6. Repeat per integration, in the build order from PRD.md.
