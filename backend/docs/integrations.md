# Sky — Integrations Setup

One-time auth setup per service. Do this before building each widget.

---

## Notion

**Type:** Integration token (simplest possible)

1. Go to https://www.notion.so/my-integrations
2. Click "New integration" → name it "Sky" → submit
3. Copy the "Internal Integration Token" → `NOTION_TOKEN`
4. Open the **Portfolio Tracker** database in Notion → "..." menu → Connections → add Sky
5. Open the **Resources** database in Notion → same step

No OAuth, no refresh tokens. Token never expires unless you revoke it.

---

## GitHub

**Type:** Personal Access Token (no OAuth)

1. Go to https://github.com/settings/tokens?type=beta (fine-grained) or classic
2. Classic PAT: scopes needed: `read:user`, `repo` (read-only is fine)
3. Copy token → `GITHUB_PAT`

For the contribution heatmap, use GitHub GraphQL API:

```graphql
query ($username: String!) {
  user(login: $username) {
    contributionsCollection {
      contributionCalendar {
        weeks {
          contributionDays {
            date
            contributionCount
          }
        }
      }
    }
  }
}
```

Endpoint: `https://api.github.com/graphql`
Auth header: `Authorization: bearer ${GITHUB_PAT}`

---

## Spotify

**Type:** OAuth 2.0 with refresh token

1. Go to https://developer.spotify.com/dashboard → Create app
2. App name: "Sky", redirect URI: `http://localhost:3000/callback`
3. Copy Client ID and Client Secret → `SPOTIFY_CLIENT_ID`, `SPOTIFY_CLIENT_SECRET`
4. Run the one-time token script (create `scripts/get-spotify-token.ts`):

```typescript
// Run once: npx ts-node scripts/get-spotify-token.ts
// Opens browser for consent, prints refresh token to copy into .env.local
const scopes = "user-read-currently-playing user-read-recently-played";
const authUrl = `https://accounts.spotify.com/authorize?client_id=${CLIENT_ID}&response_type=code&redirect_uri=http://localhost:3000/callback&scope=${encodeURIComponent(scopes)}`;
```

5. Paste the printed refresh token → `SPOTIFY_REFRESH_TOKEN`

API route pattern — exchange refresh token for access token on each request:

```typescript
const res = await fetch("https://accounts.spotify.com/api/token", {
  method: "POST",
  headers: {
    "Content-Type": "application/x-www-form-urlencoded",
    Authorization: `Basic ${Buffer.from(`${CLIENT_ID}:${CLIENT_SECRET}`).toString("base64")}`,
  },
  body: new URLSearchParams({
    grant_type: "refresh_token",
    refresh_token: REFRESH_TOKEN,
  }),
});
const { access_token } = await res.json();
```

---

## Stocks

**Type:** API key (Finnhub, free tier). TwelveData is optional.

1. Go to https://finnhub.io → sign up (free) → copy the API key → `FINNHUB_API_KEY`.
   - Quotes endpoint: `https://finnhub.io/api/v1/quote?symbol=AAPL&token=$KEY`
2. **Optional:** https://twelvedata.com → free key → `TWELVEDATA_API_KEY`.
   - Only used to draw the per-stock sparkline (`time_series`). Without it, quotes
     still render; the mini-chart is simply omitted.

Symbols are passed by the client as a query param: `/api/stocks?symbols=AAPL,MSFT`.
The native app stores its list in Settings (no env var for the symbols).

---

## Fund (Israeli mutual fund — Maya/TASE)

**Type:** None — public, key-less JSON API.

The route reads the live price from the same backend `maya.tase.co.il` uses:
`GET https://mayaapi.tase.co.il/api/fund/details?fundId=<num>`. No account, token, or
subscription. The only required input is the **fund number**, passed by the client:
`/api/fair?fund=5140785` (digits only). The native app sets it in Settings
(`sky.fair.fund`, default `5140785`).

---

## Google Calendar

**Type:** OAuth 2.0 with refresh token

1. Go to https://console.cloud.google.com → new project "Sky"
2. Enable "Google Calendar API"
3. Credentials → OAuth client ID → Web application
4. Authorized redirect URIs: `http://localhost:3000/callback`
5. Copy Client ID + Secret → `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`
6. Run one-time token script:

```typescript
// Run once locally to get refresh token
// Use googleapis package: npm i -D googleapis
import { google } from "googleapis";
const oauth2Client = new google.auth.OAuth2(
  CLIENT_ID,
  CLIENT_SECRET,
  "http://localhost:3000/callback",
);
const url = oauth2Client.generateAuthUrl({
  access_type: "offline",
  scope: ["https://www.googleapis.com/auth/calendar.readonly"],
});
```

7. Paste refresh token → `GOOGLE_REFRESH_TOKEN`

**Note:** For personal use only, OAuth consent screen verification is NOT required. Leave it in "Testing" mode and add yourself as a test user.

---

## TickTick

> **Reflects the code as built** (`lib/ticktick.ts`). The earlier OAuth
> `CLIENT_ID/SECRET/REFRESH_TOKEN` flow documented here was never wired up — the
> implementation uses the env vars below instead.

`lib/ticktick.ts` supports three auth paths; set whichever you use:

**1. MCP token (primary)** → `TICKTICK_MCP_TOKEN`
- From TickTick Web → Settings → Account → API Token.
- Calls the TickTick MCP endpoint. This is the simplest path and the one the
  `.env.local.example` points at.

**2. V2 web session (for today's tasks incl. Inbox)** → `TICKTICK_USERNAME` + `TICKTICK_PASSWORD`
- Signs in to `https://api.ticktick.com/api/v2/user/signon?wc=true&remember=true`
  with your account credentials, caches the session token ~12h, then reads
  `GET /api/v2/batch/check/0`.
- Use this if you need Inbox tasks (the V1 Open API can't see the Inbox).

**3. V1 Open API token** → `TICKTICK_ACCESS_TOKEN`
- A pre-minted OAuth access token for `https://api.ticktick.com/open/v1`.
- No Inbox access; lighter-weight than the V2 session path.

Returns full state. Filter tasks client-side by `dueDate` = today and `status = 0`.

Priority mapping: `0 = None`, `1 = Low`, `3 = Medium`, `5 = High`

---

## IBKR

The dashboard supports two official IBKR paths:

1. **Flex Web Service** - persistent read-only snapshots. Best default for a personal dashboard because it survives browser, dev-server, and local gateway restarts.
2. **Client Portal Gateway** - live local session. Useful when logged in, but IBKR intentionally requires browser login/2FA and session renewal.

### Persistent setup: Flex Web Service

**Type:** Official HTTPS reporting API with token + query ID

1. In IBKR Client Portal, open **Performance & Reports > Flex Queries > Flex Web Service Configuration**.
2. Enable Flex Web Service and generate a token. Choose a long expiry, up to 1 year.
3. Create an **Activity Flex Query** with XML output.
4. Include at least:
   - Open Positions
   - Net Asset Value
5. Copy the Flex Query ID.
6. Add to `.env.local`:

```bash
IBKR_DATA_SOURCE=flex
IBKR_FLEX_TOKEN=your_token
IBKR_FLEX_QUERY_ID=your_query_id
IBKR_FLEX_CACHE_MS=900000
```

Flex data is a reporting snapshot, not a live trading session. The widget marks it as `Flex snapshot`, and `Day P&L` is unavailable unless the report/query includes enough live-like data to derive it.

### Live setup: Client Portal Gateway

**Type:** Local gateway session

1. Run `npm run ibkr:setup` once. This downloads the official IBKR Client Portal Gateway into `tools/ibkr/`.
2. Run `npm run ibkr:start`.
3. Open `https://localhost:5001` in your browser and log in with IBKR credentials.
4. Gateway handles session auth. Your Next.js API routes call `https://localhost:5001/v1/api/*`.
5. Add to `.env.local`: `IBKR_DATA_SOURCE=gateway` and `IBKR_GATEWAY_URL=https://localhost:5001`.
6. Keep the dashboard open, or run `npm run ibkr:keepalive`, to call `/tickle` about once per minute.

**Important:** The gateway cert is self-signed. The server connector handles that locally for this official gateway URL.

IBKR still requires browser login and 2FA. Keepalive cannot bypass the daily session reset, regional midnight reset, or server maintenance.

Key endpoints:

```
GET /v1/api/portfolio/accounts                    → [{ id: accountId }]
GET /v1/api/portfolio/{accountId}/summary         → { netliquidation, unrealizedpnl, dailypnl }
GET /v1/api/portfolio/{accountId}/positions/0     → positions array
```

Gateway must be running whenever you open the dashboard. Add a note in the IBKR widget if unreachable.

---

## Groq (AI)

**Type:** API key

1. Go to https://console.groq.com → sign up (free)
2. API Keys → Create new key → `GROQ_API_KEY`
3. Free tier limits: 14,400 requests/day on most models — way more than needed for a personal dashboard

Install: `npm i groq-sdk`

```typescript
import Groq from "groq-sdk";
const groq = new Groq({ apiKey: process.env.GROQ_API_KEY });
```

Models:

- `llama-3.1-8b-instant` — fast, for greeting (sub-500ms)
- `llama-3.3-70b-versatile` — smarter, for resource URL classification
