# Sky - Sof Kol Yom (End of Day in Hebrew) - Personal Dashboard

Personal morning dashboard for Hen. One user, always live-fetched, no multi-user auth.

## Stack

Next.js 15 (App Router) · React · TypeScript · Tailwind CSS · shadcn/ui · Recharts · SWR · Groq API

## Structure

```
app/
  page.tsx              # Root dashboard
  layout.tsx
  api/
    spotify/route.ts    # GET /api/spotify
    github/route.ts     # GET /api/github
    notion/route.ts     # GET /api/notion
    calendar/route.ts   # GET /api/calendar
    ibkr/route.ts       # GET /api/ibkr
    ticktick/route.ts   # GET /api/ticktick
    ai/
      greeting/route.ts # POST - greeting card message
      resource/route.ts # POST - analyze URL, return Notion properties
components/
  widgets/              # One file per widget
  ui/                   # shadcn components only
lib/
  spotify.ts | github.ts | notion.ts | calendar.ts | ibkr.ts | ticktick.ts | groq.ts
```

See `docs/PLAN.md` for widget specs. See `docs/INTEGRATIONS.md` for auth setup per service.

## Rules

- All API calls go through `app/api/*` routes. Never call external APIs from client components.
- Every widget fetches independently with SWR. No global loading state.
- Each widget has its own skeleton loader while fetching.
- Use `react-icons/si` for brand icons (SiSpotify, SiGithub, SiNotion, etc.). No manual SVGs.
- Use shadcn Card as the base for every widget. No custom card wrappers.
- Tailwind only for styling. No inline styles. No CSS modules.
- Dark mode via `next-themes`. Class-based (`dark:`). Toggle in top-right header.
- Env vars: never hardcode keys. Always use `process.env.X`. See `.env.local.example`.
- TypeScript strict mode. Every API response has a typed interface in `lib/types.ts`.
- Error state per widget: show icon + message, never crash the whole dashboard.

## Electron & Desktop Build

- Build command: `npm run electron:build` (runs `next build && electron:compile && electron-builder`).
- Output: `release/<version>/` — DMG and zip for macOS arm64.
- Mac icon: uses a macOS `.icon` bundle at `public/Mac Icon.icon/`. This requires full Xcode (not just Command Line Tools) because electron-builder uses `actool` to compile it. Ensure `xcode-select -p` points to `/Applications/Xcode.app/Contents/Developer` before building. If it doesn't, run `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`.
- DMG background: `electron/build/background.png` (720x402) + `background@2x.png` (1440x804) for Retina. Dimensions must exactly match `dmg.window` in `electron-builder.yml`.
- Do not convert the `.icon` bundle to `.icns` — the `.icon` format supports macOS icon theming (Liquid Glass).

## Do Not

- Do not create Supabase tables or any database - data is always live-fetched.
- Do not use the Anthropic API for data fetching - use Groq for AI features only.
- Do not add authentication - this is a single-user personal app.
- Do not add navigation - single page dashboard only.
- Do not use `pages/` router - App Router only.
- Do not replace the `.icon` bundle with `.icns` — macOS icon theming requires the `.icon` format.
