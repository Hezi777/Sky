# Integrations - auth, endpoints, gotchas

Read the relevant section before wiring an integration. One integration per session.
Difficulty summary: Spotify / Google Calendar / GitHub / Notion = easy. TickTick = easy
(was a worry, now solved). Fair = semi-automated tracker. IBKR = the hard one.

## Spotify  (easiest)
- Standard OAuth 2.0 (Authorization Code + refresh token).
- Endpoints: `GET /v1/me/player/recently-played`, `GET /v1/me/playlists`.
- Scopes: user-read-recently-played, playlist-read-private.
- Gotcha: tokens expire in 1h - refresh in the cron job.

## Notion
- Official API + you already have the Notion connector working.
- Quick-add flow: fetch DB schema -> build properties -> create page.
- data_source_id: 31f86eb0-7b69-80e2-9ec4-000b45acce82
- AI description: server-side call to Groq (model: llama-3.1-8b-instant) with the
  URL/title as input -> 1-2 sentence description. No Anthropic API key available;
  Groq's free tier is more than enough for occasional Notion adds and you already
  have a Groq key from the Whisper transcription work. API is OpenAI-compatible -
  use the openai SDK pointed at https://api.groq.com/openai/v1.
- Gotcha: validate Category against the allowed select options before insert.

## Google Calendar
- OAuth 2.0. Endpoint: `events.list` with timeMin/timeMax = today.
- Scope: calendar.readonly.
- Apple Calendar: no public API. Sync Apple->Google, read Google only.

## GitHub
- A fine-grained Personal Access Token (read-only, scoped to your repos) is enough -
  simpler than an OAuth app.
- Endpoints: `GET /repos/{owner}/{repo}/actions/runs?per_page=1`,
  `GET /repos/{owner}/{repo}/pulls?state=open`.
- Gotcha: store the PAT in oauth_tokens/env, never in the client bundle.

## TickTick  (easy - corrected)
- Open API: register an app at developer.ticktick.com -> client ID + secret -> OAuth2.
  Base URL https://api.ticktick.com/open/v1. Redirect URI to localhost during setup.
- Working MCP servers now exist (jacepark12/ticktick-mcp, ekkyarmandi/ticktick-mcp,
  and a hosted one via Arcade). The previous "no working TickTick integration" note is
  OUTDATED - this is solved. Use the REST API directly or an MCP, your choice.
- Endpoint: list projects, list tasks, filter to today + incomplete.
- Gotcha: token refresh; confirm exact task-filter params against the live API.

## Fair  (semi-automated tracker, not a plain manual number)
Fair itself has no API. But the fund is public: Meitav money market fund 5140785.
- Price source (best-effort, pick one and add a manual fallback):
  - TASE Maya mutual-fund data (maya.tase.co.il) - the site is backed by an internal
    JSON API; usable for personal low-volume reads but undocumented and may change.
    Requests typically need browser-like headers.
  - Fair's own fund directory page funds.fair.co.il/search/funds/5140785 and aggregators
    (Globes) also show the daily price.
  - MANUAL override field is the reliable fallback. It is a קרן כספית (near-flat NAV),
    so a daily/weekly price is plenty - do not over-engineer the fetch.
- Data model: see ARCHITECTURE.md (fair_fund, fair_contributions, fair_dca). Store units
  at purchase price; value = units * latest price; gain = value - contributed.
- DCA: editable settings form (amount, frequency, day, active) writes fair_dca; a daily
  job checks next_date and creates the expected contribution for me to confirm.
- Do NOT scrape or automate the Fair account login itself - only the public fund price.

## Interactive Brokers  (hardest - do last)
- Direct OAuth 2.0 is INSTITUTIONAL-ONLY. Third-party vendor access is OAuth 1.0a and
  needs IBKR compliance approval - not worth it for personal use.
- Individual retail paths:
  1. Flex Web Service (PREFERRED): set up a Flex query (positions/NAV/balances) in
     account management, get a Flex token, a scheduled job pulls the statement (XML/JSON)
     and writes cache_ibkr. Token-based, read-only, no live session, no Java daemon.
     Best fit for "value + daily change".
  2. Client Portal Gateway: Java program, manual browser login on the same machine,
     periodic re-auth. Heavier - only if Flex is missing a field you need.
- No clean MCP. Treat as a separate worker/job.
