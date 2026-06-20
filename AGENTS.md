# Sky — Agent Guide

This file orients AI agents (Claude Code, Copilot, Cursor, etc.) working in this repo.
For coding rules, conventions, and do-nots, see **CLAUDE.md** (the canonical source).

## Repo Layout

```text
app/              Next.js App Router pages + API route handlers (the backend)
components/       Web dashboard components and widgets
lib/              Integration clients, shared types, Groq helpers
hooks/            React hooks (SWR-based state)
electron/         Electron shell source (TypeScript)
electron-dist/    Compiled Electron output (generated, gitignored)
native/           SwiftUI macOS/iOS client (XcodeGen-driven)
  project.yml     XcodeGen source of truth
  Sky/            Swift source, models, stores, views, assets
  .build*/        Xcode build output (generated, gitignored)
  Sky.xcodeproj/  Generated Xcode project (gitignored)
public/           Static assets, .icon bundle for Electron
assets/           DMG backgrounds, icon sources, design assets
scripts/          OAuth token helpers, build utilities
tools/            Local dev tools (IBKR gateway binaries, gitignored)
docs/             Integration auth setup, desktop app docs, screenshots
release/          Built app binaries (generated, gitignored): electron/<version>/, native/<version>/
```

## Key Entry Points

- **Web dashboard**: `app/page.tsx` renders `components/dashboard.tsx`
- **API routes**: `app/api/*/route.ts` — all external service calls go here
- **Widgets**: `components/widgets/` — each widget fetches independently via SWR
- **Types**: `lib/types.ts` — TypeScript types for all API responses
- **Native models**: `native/Sky/Models/` — Swift Codable types mirroring `lib/types.ts`
- **Electron main**: `electron/main.ts`

## Agent Workflow Notes

- Run `npm run lint` and `npm run build` before declaring any web/API task done.
- Native builds: `npm run native:generate && npm run native:build`.
- The three surfaces share the API layer (`app/api/*`). Changes to API response shapes must update both `lib/types.ts` and `native/Sky/Models/`.
- `native/project.yml` is canonical; never hand-edit `native/Sky.xcodeproj/`.
- Secrets live in `.env.local` (gitignored). See `.env.local.example` for the full list and `docs/integrations.md` for per-service auth setup.
- No database, no auth, no page navigation, single-page dashboard. See CLAUDE.md "Do Not" section.
