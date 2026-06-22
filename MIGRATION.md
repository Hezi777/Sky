# Migration — one tangled root → three sibling roots

Branch: `chore/restructure-folders`

Sky was one Next.js root that doubled as web UI + API backend, plus an Electron shell and
a SwiftUI app. It is now three independent single-stack roots:

| Folder | Stack | Role | Builds with |
|---|---|---|---|
| `backend/` | Next.js 16 (headless) | API + contract source (`lib/types.ts`) | `cd backend && npm run dev` → `http://localhost:3000` |
| `native/` | Swift 6 / SwiftUI / XcodeGen | Primary client | `cd native && xcodegen generate && ./build-mac.sh` |
| `legacy-web/` | Next.js + Electron | **Frozen** web/Electron, reference only | not built |

## What moved where

All moves used `git mv` (history preserved); rename detection in `git log --follow` works.

### → `backend/`
- `app/api/**` (all 15 routes) — the API surface.
- `lib/**` (16 files incl. `__tests__/`) — integration clients + `types.ts` contract.
  **`app/api/` and `lib/` were kept together and never split** (hard rule).
- `scripts/get-{google,spotify,ticktick}-token.mjs`, `scripts/ibkr/**`, `scripts/README.md`.
- `package.json`, `package-lock.json`, `next.config.ts`, `tsconfig.json`,
  `eslint.config.mjs`, `next-env.d.ts`, `.env.local.example`.
- `docs/integrations.md`.
- **Added**: stub `app/page.tsx` + `app/layout.tsx` so the headless app still builds with
  no UI.

### → `legacy-web/` (frozen)
- Real `app/page.tsx`, `app/layout.tsx`, `app/globals.css`, `app/icon.svg`.
- `components/**` (all 24, including the 6 dead files below), `hooks/**`.
- `electron/**`, `electron-builder.yml`, `.github/workflows/desktop.yml`.
- `public/**`, `assets/dmg`, `assets/icons`, `assets/source`.
- `scripts/{screenshot.mjs,build-dmg.sh,fix-dmg.sh,fix-dmg.js}`, `scripts/icons/**`.
- `postcss.config.mjs`, `components.json`, `docs/desktop.md`, `docs/screenshots/**`.
- **Frozen copies** (not moves): `lib/` (verbatim snapshot of `backend/lib`), plus
  `package.json`, `package-lock.json`, `next.config.ts`, `tsconfig.json`,
  `eslint.config.mjs`, `next-env.d.ts`, `.env.local.example` — so the archive is
  self-described. None of it is built or guaranteed to resolve.
- **Added**: `README.md` marking the folder frozen.

### `native/` — unchanged
Stayed in place. Confirmed no dependency on root/backend scripts; builds standalone.

## Dead files — moved, not deleted
Per the snapshot, these had zero live imports. They were moved into `legacy-web/` rather
than deleted (nothing referenced was removed):
`components/widgets/github-repos.tsx`, `components/widgets/greeting-card.tsx`,
`components/glass-card.tsx`, `components/memoji-picker.tsx`,
`components/layout/header.tsx`, `components/layout/sidebar.tsx`.

## The `lib/` coupling decision
Every live web component imports `@/lib/*`, but the hard rule requires `lib/` to live with
`app/api/` in `backend/`. Resolution: `lib/` is **canonical in `backend/`** and copied
verbatim into `legacy-web/lib/`. Since `legacy-web` is frozen (never edited, built, or
typechecked), the copy can never drift. The frozen imports are not wired up or verified —
`legacy-web/README.md` says so explicitly.

The reverse direction is clean: **no `app/api/` or `lib/` file imports any frontend code**,
so the backend extracts with zero coupling to the web UI.

## `backend/package.json` changes
- Name → `sky-backend`; dropped Electron `main`/`productName`.
- Removed scripts: `electron:*`, `native:*` (native builds from `native/`).
- Kept: `dev`, `build`, `start`, `lint`, `ibkr:*`.
- Pruned dependencies to what `app/api/` + `lib/` actually import (verified by import scan):
  kept `@notionhq/client`, `clsx`, `fast-xml-parser`, `groq-sdk`, `next`, `react`,
  `react-dom`, `tailwind-merge`; dropped all frontend/Electron deps (framer-motion,
  recharts, swr, tailwindcss, electron, electron-builder, etc.). `npm install` →
  352 packages.
- `legacy-web/package.json` retains the original full script/dep set (frozen).

## Duplicated-by-design assets (untouched)
Cloud/sky artwork and the adaptive icon source exist in both `legacy-web/public/` and
`native/Sky/Assets.xcassets/` / `native/Sky/AppIcon.icon/`. These are platform packaging
inputs; each surface keeps its own copy.

## Verification
- **backend**: `npm install` (clean), `npm run dev` boots on `http://localhost:3000`,
  `GET /api/fair?fund=5113022` → **HTTP 200** (also `/api/spotify` → 200). The native-app
  contract origin is preserved.
- **native**: `cd native && ./build-mac.sh` → **Build Succeeded**, artifact at
  `native/.build/Build/Products/Debug/Sky.app`.

## Notes / not done
- `legacy-web` Electron `extraResources` still reference `.next/standalone` + `public`
  relative paths. Not updated — the folder is frozen and not built. If revived, repoint
  these to the new layout.
- A stale root `next-server` was holding `:3000` during verification (the pre-split dev
  server) and was stopped so backend could rebind to `:3000`.
- Generated/ignored dirs (`node_modules/`, `.next/`, `electron-dist/`, `release/`,
  `tools/`, `native/.build/`) were left in place; they regenerate per-folder.
