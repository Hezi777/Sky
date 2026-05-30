# Architecture

Stack verified current as of May 2026: Next.js 16.2.x (App Router, Turbopack),
React 19.2, TypeScript 5.x, Supabase via @supabase/ssr 0.10.x, Tailwind 4.x, Biome 2.x.

## Core decision
Read-mostly aggregator. The UI NEVER calls external APIs on render. Scheduled jobs
pull from each API into Supabase; pages read the cached rows. This avoids juggling 6
OAuth token refreshes on every page load.

## Data flow
External API  ->  cron job (Vercel cron / route handler)  ->  Supabase (cache + tokens)
->  Next.js Server Component reads Supabase  ->  dashboard UI

## Next.js 16 notes that affect the code
- Server Components: params and searchParams are async - `const { id } = await params`.
- cookies() and headers() are async - await them (the Supabase ssr client setup uses cookies()).
- Turbopack is the default bundler for dev and build.
- Caching: dynamic fetch() is uncached by default; add `next: { revalidate }` where wanted.

## Supabase client setup (@supabase/ssr 0.10.x)
- Use @supabase/ssr, NOT the deprecated @supabase/auth-helpers-* packages.
- Create two helpers: a browser client and a server client (server client reads cookies()).
- Prefer the new API keys: sb_publishable_... (client) and sb_secret_... (server-only).
  The legacy anon / service_role keys still work through end of 2026 but are being retired.
- Cron jobs and server-side writes use the secret key; never expose it client-side.

## Tables (Supabase)
- `oauth_tokens` (provider, access_token, refresh_token, expires_at) - server-only access
- `cache_spotify` (last_track json, last_playlist json, updated_at)
- `cache_calendar` (events json, updated_at)
- `cache_github` (repos json: name, last_run_conclusion, open_pr_count, updated_at)
- `cache_ticktick` (tasks json, updated_at)
- `cache_ibkr` (total_value, day_pnl, day_pnl_pct, positions json, updated_at)

### Fair fund tracker (3 tables, written by me + a price job)
- `fair_fund` (fund_number '5140785', name, latest_unit_price, price_updated_at,
  price_source 'auto'|'manual')
- `fair_contributions` (id, date, amount_nis, unit_price_at_purchase, units)
    units = amount_nis / unit_price_at_purchase (compute on insert).
    Current value = SUM(units) * fair_fund.latest_unit_price.
    Gain/loss = current value - SUM(amount_nis).
- `fair_dca` (amount_nis, frequency 'monthly', day_of_month, active bool, next_date)
    The DCA settings form writes here. A job (or a reminder) uses next_date to create
    the expected contribution; I confirm the real one. Editable from the dashboard.

Enable RLS; single-user so policies can be simple, but never rely on the client for
token reads or for writing fund/contribution rows.

## Cron schedule (suggested)
- Spotify, Calendar, TickTick, GitHub: every 15-30 min
- IBKR: a few times/day (Flex statement refresh)
- Fair fund price: daily (or a few times/week - it is a money market fund, near-flat)
- Fair DCA contribution creation: daily check against next_date

## Token storage
All OAuth tokens in `oauth_tokens`, refreshed by the cron job before use. Never in
code, never in the client bundle. Refresh logic lives server-side only.

## IBKR note (the hard one)
Direct OAuth 2.0 is INSTITUTIONAL-ONLY - not available to an individual retail account.
Two realistic individual paths:
1. Flex Web Service (PREFERRED for this app): token-based, read-only, scheduled
   statements with positions/balances. No Java daemon, no live session. Best fit for
   "show value + daily change". Set up a Flex query in account management, get a token,
   a scheduled job fetches the statement and writes cache_ibkr.
2. Client Portal Gateway: a Java program that must run on the same machine with a
   MANUAL browser login and periodic re-auth. Heavier; only if Flex lacks a field you need.
Treat IBKR as a separate worker/job, not a Vercel route doing live calls.

## Fair note
No public API. Track the underlying public fund (5140785) price - best-effort fetch
(see integrations.md) with a manual override field as fallback. Contributions and DCA
settings are entered by me through small forms. This is a real holdings tracker, not a
single manual balance.
