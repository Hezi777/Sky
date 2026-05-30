# CLAUDE.md

## What this is
Personal all-in-one dashboard that aggregates my own accounts into one web app:
Google Calendar, Notion (Resources DB), Interactive Brokers, Fair (Israeli קרן -
tracked as a real DCA/holdings tracker, see below), Spotify, TickTick, GitHub.
Read-mostly. Single user (me).

## Stack (verified current as of May 2026)
- Next.js 16.2.x (App Router, Turbopack) + React 19.2 + TypeScript 5.x
- Supabase (Postgres) via @supabase/ssr 0.10.x for cached data + token storage
- Tailwind CSS 4.x (CSS-first config via @theme, no tailwind.config.js)
- shadcn/ui - component library built on Radix UI primitives; use for all UI components.
  Init with `pnpm dlx shadcn@latest init` (choose Tailwind 4 / CSS variables when prompted).
  Add components with `pnpm dlx shadcn@latest add <component>`. Never copy-paste component
  source manually - always use the CLI so versions stay in sync.
- Biome 2.x for lint + format (runs via a Stop hook, not by hand)
- Scheduled jobs (Vercel cron) pull from each API into Supabase; the UI reads the cache.
  Do NOT call external APIs on page render. See docs/ARCHITECTURE.md.

## Next.js 16 gotchas (these will bite if ignored)
- params, searchParams, cookies(), headers(), draftMode() are ASYNC - always await.
- Node 20.9+ required. TS 5.1+ required.
- Use @supabase/ssr (auth-helpers packages are deprecated, do not use them).

## Commands
- `pnpm dev` - run locally (Turbopack)
- `pnpm build` - production build
- `pnpm verify` - typecheck + `biome check` (run before considering a task done)

## How to work here
- Read docs/PRD.md before starting a new feature; read docs/ARCHITECTURE.md before
  touching data flow, tables, or cron.
- Build ONE integration at a time. Each is self-contained.
- Per-integration auth quirks live in docs/agent/integrations.md - read it before
  wiring any API. Notably: Fair has no API (track the underlying fund's public price +
  manual contributions), IBKR uses Flex Web Service or the CP Gateway, not clean OAuth,
  and Notion AI descriptions use Groq (not the Anthropic API - no key available).
- Use Plan Mode for anything touching more than one file. Show the plan first.
- Track progress in PROGRESS.md as you go.
- Full build process: docs/WORKFLOW.md (design -> code -> shipped).

## Detailed docs (read when relevant, not always)
- docs/WORKFLOW.md - end-to-end process: Claude Design -> Claude Code -> finished
- docs/PRD.md - what each widget should do + acceptance criteria
- docs/ARCHITECTURE.md - data flow, tables, cron, token storage
- docs/agent/integrations.md - per-API auth, endpoints, gotchas
- docs/agent/running-locally.md - env vars, OAuth setup, how to run cron locally
- design/DESIGN_BRIEF.md - the Claude Design prompts + design tokens

## Non-negotiables
- Never commit secrets. Tokens live in Supabase / env, never in code.
- No em dashes in any user-facing copy; use hyphens.
