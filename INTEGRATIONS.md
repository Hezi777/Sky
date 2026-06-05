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

**Type:** OAuth 2.0

1. Go to https://developer.ticktick.com → register developer account
2. Create new app → set redirect URI to `http://localhost:3000/callback`
3. Copy Client ID + Secret → `TICKTICK_CLIENT_ID`, `TICKTICK_CLIENT_SECRET`
4. OAuth endpoints:
   - Auth: `https://ticktick.com/oauth/authorize`
   - Token: `https://ticktick.com/oauth/token`
   - Scopes: `tasks:read`
5. Run one-time token script (same pattern as Spotify/Google)
6. Paste refresh token → `TICKTICK_REFRESH_TOKEN`

Task endpoint after auth:

```
GET https://api.ticktick.com/api/v2/batch/check/0
```

Returns full state. Filter tasks client-side by `dueDate` = today and `status = 0`.

Priority mapping: `0 = None`, `1 = Low`, `3 = Medium`, `5 = High`

---

## IBKR Client Portal API

**Type:** Local gateway session (most complex setup)

1. Download IBKR Client Portal Gateway: https://www.interactivebrokers.com/en/trading/ib-api.php
2. Extract and run: `cd clientportal.gw && bin/run.sh root/conf.yaml` (Mac/Linux)
   - Windows: `bin\run.bat root\conf.yaml`
3. Open https://localhost:5000 in browser → log in with IBKR credentials
4. Gateway handles session auth. Your Next.js API routes call `https://localhost:5000/v1/api/*`
5. Add to `.env.local`: `IBKR_GATEWAY_URL=https://localhost:5000`

**Important:** The gateway cert is self-signed. In development, either:

- Set `NODE_TLS_REJECT_UNAUTHORIZED=0` in dev (not production)
- Or add the gateway cert to your system trust store

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
