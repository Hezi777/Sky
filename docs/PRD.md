# PRD - Personal Dashboard

Stack target (verified May 2026): Next.js 16.2.x, React 19.2, Supabase (@supabase/ssr),
Tailwind 4, Biome 2. See docs/ARCHITECTURE.md for the why and the Next 16 async-API caveats.

## Purpose
One web app where I see the state of my life and money at a glance, without opening
6 apps. Read-mostly aggregator. Single user (me). Not real-time - cached, refreshed
on a schedule.

## Build order (by effort, easiest first)
1. Spotify - recently played / last playlist
2. Notion - Resources quick-add with AI auto-description
3. Google Calendar - today's events
4. GitHub - latest Actions runs, open PRs (Glass IDE, SheetSync)
5. TickTick - today's tasks (Open API + working MCP, easy now)
6. Fair - DCA/holdings tracker (auto fund price + manual contributions)
7. Interactive Brokers - holdings + daily change (hardest; use Flex Web Service)

## Widgets

### Spotify
- Show last played track and most recent playlist.
- Acceptance: widget shows track name, artist, playlist name, links to Spotify.

### Notion - Resources quick-add (the AI piece)
- AI description: paste URL -> app fetches metadata, calls Groq (llama-3.1-8b-instant)
  to generate a short description, writes the row to Resources DB.
- DB data_source_id: 31f86eb0-7b69-80e2-9ec4-000b45acce82
- Properties: Name, URL, Description, Status (Saved/Reading/Using), Category
  (Claude Code, UI Components, Design Inspo, AI Tools, Dev Infrastructure, SaaS/Biz,
  Learning, BI/Data, Tools)
- Always fetch DB schema first, then insert.
- Acceptance: paste URL -> row appears in Notion with an AI-written Description and a
  sensible Category. Status defaults to Saved.

### Google Calendar
- Today's events, time + title. Read-only.
- Apple Calendar: no public API - out of scope, sync Apple->Google and read Google.
- Acceptance: today's events render in time order.

### GitHub
- Latest Actions run status + open PRs for my active repos.
- Acceptance: per repo, show last workflow conclusion (success/fail) and open PR count.

### TickTick
- Today's incomplete tasks.
- Open API at developer.ticktick.com (OAuth2, base https://api.ticktick.com/open/v1).
  Working MCP servers exist now (jacepark12 / ekkyarmandi / Arcade) - the old
  "no working integration" problem is resolved. Use the REST API or an MCP.
- Acceptance: list of today's tasks with title.

### Fair - DCA / holdings tracker  (upgraded from a manual number)
Fair has no API, but my fund is public: Meitav money market fund number 5140785.
Israeli funds publish a daily unit price by law, so track the FUND price automatically
and only input CONTRIBUTIONS manually. Store units at purchase price for accuracy.
- Log a contribution: date + amount (NIS). App computes units = amount / unit-price-that-day.
- Current value = total units held * latest unit price.
- Gain/loss = current value - total contributed.
- DCA settings editable in the dashboard: amount (e.g. 300 NIS), frequency (monthly),
  day of month, active on/off. App auto-creates the expected contribution on schedule
  (I confirm it happened) or reminds me.
- Price source is best-effort (see integrations.md). Always provide a manual
  price-override field as fallback - the fund is a קרן כספית so a stale/weekly price
  is fine.
- Acceptance: I can add contributions and edit DCA settings; the card shows current
  value, total contributed, and gain/loss, with a last-price-updated date.

### Interactive Brokers
- Total value + daily change/percent, top positions.
- Read-only via the Flex Web Service (token-based, scheduled statements) is preferred
  over the live CP Gateway. Direct OAuth 2.0 is institutional-only - not available to
  an individual retail account. See integrations.md.
- Acceptance: shows portfolio value and day change. Pulled by a scheduled job, not live.

## Out of scope (v1)
Live trading, writes to brokerage, push notifications, multi-user, mobile-native app,
weather/news noise.
