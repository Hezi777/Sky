# Progress

Update this as you finish things. One integration per session; /clear between them.
Full process in docs/WORKFLOW.md.

## Design (Claude Design)
- [ ] Dashboard shell designed (light + dark) and approved
- [ ] All widgets styled, RTL checked, self-critique done
- [ ] Handed off to Claude Code

## Setup
- [ ] Next.js 16 + TS + Tailwind 4 scaffolded
- [ ] @theme tokens from design/DESIGN_BRIEF.md added
- [ ] Supabase project + tables created (see docs/ARCHITECTURE.md)
- [ ] @supabase/ssr browser + server clients
- [ ] Biome configured + Stop hook running format/lint
- [ ] Dashboard shell layout wired (grid of widget slots, dark toggle)

## Integrations (build order)
- [ ] Spotify - recently played + last playlist
- [ ] Notion - Resources quick-add with AI description
- [ ] Google Calendar - today's events
- [ ] GitHub - Actions status + open PRs
- [ ] TickTick - today's tasks (Open API / MCP - easy now)
- [ ] Fair - fund price fetch + contributions + DCA settings (manual price fallback)
- [ ] Interactive Brokers - Flex Web Service -> value + day change

## Ship
- [ ] Deployed to Vercel, env vars set
- [ ] Vercel cron jobs scheduled
- [ ] Dark mode + RTL polished in the live build

## Notes / blockers
-
