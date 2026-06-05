# OAuth Token Scripts

One-time scripts to obtain refresh tokens for Spotify, Google Calendar, and TickTick.
Each script reads `CLIENT_ID`/`CLIENT_SECRET` from `.env.local`, starts a local callback
server, and prints the exact line to paste into `.env.local`.

No extra dependencies - runs with plain `node` (Node 18+).

---

## Spotify

**1. Register redirect URI in Spotify dashboard**
- URL: https://developer.spotify.com/dashboard → select your app → Edit Settings → Redirect URIs
- Add: `http://127.0.0.1:8888/callback`

> Note: As of April 2025, Spotify enforces 127.0.0.1 (not `localhost`) for loopback URIs.
> The script uses PKCE (no client secret sent) as required for new Spotify apps.

**2. Run**
```
node scripts/get-spotify-token.mjs
```

**3. Paste into `.env.local`**
```
SPOTIFY_REFRESH_TOKEN=<value printed in terminal>
```

---

## Google Calendar

**1. Register redirect URI in Google Cloud Console**
- URL: https://console.cloud.google.com/apis/credentials → your OAuth 2.0 Client ID → Authorized redirect URIs
- Add: `http://127.0.0.1:8889/callback`
- Also ensure the Calendar API is enabled: https://console.cloud.google.com/apis/library/calendar-json.googleapis.com

> If no `refresh_token` appears, revoke existing access at https://myaccount.google.com/permissions
> and run again (the `prompt=consent` flag forces a fresh grant).

**2. Run**
```
node scripts/get-google-token.mjs
```

**3. Paste into `.env.local`**
```
GOOGLE_REFRESH_TOKEN=<value printed in terminal>
```

---

## TickTick

**1. Register redirect URI in TickTick developer portal**
- URL: https://developer.ticktick.com/manage → your app → OAuth redirect URI
- Add: `http://127.0.0.1:8890/callback`

**2. Run**
```
node scripts/get-ticktick-token.mjs
```

**3. Paste into `.env.local`**
```
TICKTICK_REFRESH_TOKEN=<value printed in terminal>
```
