# Sky — Personal Dashboard

Single-user morning dashboard for Hen. Always live-fetched, no database, no auth.

This repo is split into **three independent sibling roots**, each its own single-stack project:

```
Sky/
├── backend/      Headless Next.js API. Serves /api/* on http://localhost:3000.
├── native/       SwiftUI macOS/iOS client. The PRIMARY client. Calls backend's /api/*.
└── legacy-web/   FROZEN web frontend + Electron. Reference only — never edit or build.
```

See `docs/ARCHITECTURE.md` for the full map and `MIGRATION.md` for how the split was done.

## The three folders

### `backend/` — the API and the contract source
- Headless Next.js App Router app. Only `app/api/*` routes + a stub `app/page.tsx`/`layout.tsx`.
- `lib/` holds the integration clients, utilities, and **`lib/types.ts` — the single source of truth for API response shapes.** Never split `app/api/` and `lib/` apart; they move and live together.
- `backend/` is the only folder that runs in normal development. `npm run dev` from `backend/` must keep serving `http://localhost:3000/api/*` — the native app depends on that exact origin.

### `native/` — the primary client
- XcodeGen-driven Swift 6 / SwiftUI app. `native/project.yml` is canonical; `native/Sky.xcodeproj/` is generated — do not hand-edit.
- Builds standalone from within `native/`: `xcodegen generate` then `./build-mac.sh`. No dependency on root or backend scripts.
- Native models in `native/Sky/Models/*.swift` mirror `backend/lib/types.ts` by hand. Changing an API response shape requires synchronized edits on both sides.
- Calls `backend`'s `/api/*` for all privileged integrations. Do not put API keys or broker credentials in Swift.

### `legacy-web/` — FROZEN, never touched
- The old web dashboard (`app/page.tsx`, `components/`, `hooks/`) and the Electron shell (`electron/`, `electron-builder.yml`).
- Kept for reference. **Do not edit, lint, build, or "fix" anything here.** Its `lib/` is a frozen snapshot copy of `backend/lib/`; its imports are not guaranteed to resolve.
- If web/Electron is ever revived, it becomes its own project — not part of this restructure.

## Commands

Run each from inside its own folder.

```bash
# backend/
npm run dev              # Next.js API at http://localhost:3000
npm run build            # production build
npm run lint             # eslint
npm run ibkr:start       # local IBKR Client Portal Gateway

# native/
xcodegen generate        # regenerate Sky.xcodeproj from project.yml
./build-mac.sh           # build unsigned macOS app → .build/Build/Products/Debug/Sky.app
./build-dmg.sh           # package DMG (after build-mac.sh)
```

## Rules

- All external API calls go through `backend/app/api/*` route handlers. Clients (native, frozen web) never call external APIs directly — except the native-only public widgets (Open-Meteo weather, ZenQuotes) by design.
- Env vars: never hardcode keys. Always `process.env.X`. See `backend/.env.local.example`.
- TypeScript strict mode. API responses typed in `backend/lib/types.ts` — the contract.
- See `backend/docs/integrations.md` for auth setup per service.

## Do Not

- Do not edit anything under `legacy-web/` — it is frozen.
- Do not split or delete `backend/app/api/` and `backend/lib/` — they are the contract and must stay together.
- Do not create a database — data is always live-fetched.
- Do not add authentication — single-user personal app.
- Do not use the Anthropic API — use Groq for AI features.
- Do not hand-edit `native/Sky.xcodeproj/` — `native/project.yml` is canonical.
