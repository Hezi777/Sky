# Sky — Personal Dashboard

Single-user morning dashboard for Hen. Always live-fetched, no database, no auth.

## Stack

Next.js 15 (App Router) · React · TypeScript · Tailwind CSS v4 · shadcn/ui · Recharts · SWR · Groq API · Electron

## Commands

```bash
npm run dev              # Next.js dev server
npm run build            # production build
npm run lint             # eslint
npm run electron:dev     # Electron shell with hot-reload
npm run electron:build   # production Electron build → release/<version>/
```

## Rules

- All external API calls go through `app/api/*` route handlers. Never call external APIs from client components.
- Every widget fetches independently with SWR. No global loading state.
- Each widget has its own skeleton loader and per-widget error state.
- Brand icons use `BrandLogo` component (maps to `/public/assets/integrations/`). UI icons use `@iconify/react` or `lucide-react`.
- Tailwind only for styling. No inline styles. No CSS modules.
- Dark mode via `next-themes`, class-based (`dark:`).
- Env vars: never hardcode keys. Always `process.env.X`. See `.env.local.example`.
- TypeScript strict mode. API responses typed in `lib/types.ts`.
- See `docs/integrations.md` for auth setup per service.

## Electron

- Mac icon: `.icon` bundle at `public/Mac Icon.icon/` — do NOT replace with `.icns` (supports Liquid Glass theming).
- `.icon` compilation requires full Xcode, not just Command Line Tools. Ensure `xcode-select -p` → `/Applications/Xcode.app/Contents/Developer`.
- DMG backgrounds live in `assets/dmg/`. Dimensions must match `dmg.window` in `electron-builder.yml`.
- Icons (`.icns`, `.ico`) live in `assets/icons/`.

## Do Not

- Do not create a database — data is always live-fetched.
- Do not add authentication — single-user personal app.
- Do not add page navigation — single page dashboard only.
- Do not use `pages/` router — App Router only.
- Do not use the Anthropic API — use Groq for AI features.
