# legacy-web — FROZEN

This is the **frozen** former web frontend and Electron shell of Sky. It is kept for
reference only.

**Do not edit, build, lint, or run anything in this folder.** It is not maintained.

Imports are not guaranteed to resolve; this code is kept for reference only.

## What's here

- `app/page.tsx`, `app/layout.tsx`, `app/globals.css`, `app/icon.svg` — the old web dashboard entry.
- `components/`, `hooks/` — the React UI (including dead files that predated the freeze).
- `electron/`, `electron-builder.yml` — the Electron desktop shell that packaged the web app.
- `public/`, `assets/dmg`, `assets/icons` — web/Electron runtime and packaging assets.
- `scripts/` — Electron DMG, icon generation, and screenshot tooling.
- `.github/workflows/desktop.yml` — the old desktop build CI.
- `lib/` — a **verbatim snapshot copy** of `backend/lib/` taken at split time, so the
  archived `@/lib/*` imports point at real files. The canonical `lib/` lives in `../backend`.

## Live code

The maintained project lives in the sibling folders:

- `../backend` — the headless Next.js API (`/api/*` on `http://localhost:3000`), the contract source.
- `../native` — the SwiftUI client, the primary surface.

If the web/Electron surface is ever revived, treat it as a new project built fresh against
`../backend`'s API — not as an in-place edit of this frozen archive.
