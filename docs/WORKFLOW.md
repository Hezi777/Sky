# Workflow - from design to shipped product

The full path: Claude Design (look) -> handoff -> Claude Code (build) -> Vercel (ship).
The docs in this repo are the source of truth at every phase. Read this once, then work
phase by phase.

---

## Phase 0 - Prep (once)
Put this whole folder in your repo root so both tools can see it:

    your-repo/
      CLAUDE.md
      PROGRESS.md
      docs/
        WORKFLOW.md          (this file)
        PRD.md
        ARCHITECTURE.md
        agent/
          integrations.md
          running-locally.md
      design/
        DESIGN_BRIEF.md

Then create a private GitHub repo and push, so Claude Code has somewhere to land.

---

## Phase 1 - Design in Claude Design
Goal: a polished UI shell you love, in light + dark. Not the real app yet.

1. Open Claude Design (Pro/Max/Team, Anthropic Labs). It is a separate canvas workspace.
2. Attach the three reference screenshots + paste the OPENING PROMPT from
   design/DESIGN_BRIEF.md. Generate the shell.
3. Refine card by card using the ITERATION PROMPTS. Use the adjustment sliders and
   inline comments, not just chat - they are faster for small tweaks.
4. Run the dark-mode prompt and the RTL (Hebrew) prompt. Do these now, not later -
   retrofitting either is painful.
5. Ask Claude Design to critique its own design for contrast, hierarchy, accessibility.
   Apply what makes sense.
6. Lock the design tokens (colors/radius/type) to the values in DESIGN_BRIEF.md so the
   handoff produces code that matches your Tailwind 4 @theme block.

Output of this phase: an approved visual design + a handoff bundle.

---

## Phase 2 - Handoff to Claude Code
1. Use Claude Design's "hand off to Claude Code" bundle (one instruction). It ships the
   design + context across.
2. Point Claude Code at THIS repo. First message should tell it to read CLAUDE.md,
   docs/PRD.md, and docs/ARCHITECTURE.md before doing anything.
3. Be explicit that the design is the UI shell only - the real app reads cached Supabase
   data per ARCHITECTURE.md. The design's mock data is NOT the implementation.

---

## Phase 3 - Build in Claude Code
Golden rules (these are what make it smooth, not painful):
- Use Plan Mode for anything touching more than one file. Read the plan before it writes.
- Build ONE integration per session. /clear between integrations so context stays clean.
- Run `pnpm verify` before calling any task done.
- Update PROGRESS.md at the end of each session.

Order:
1. SETUP session: scaffold Next.js 16, add Tailwind 4 @theme tokens, set up the two
   @supabase/ssr clients, create the Supabase tables (ARCHITECTURE.md), wire the Biome
   Stop hook, build the static dashboard shell + dark toggle from the design.
2. Then one integration per session, in PRD.md build order:
   Spotify -> Notion -> Google Calendar -> GitHub -> TickTick -> Fair -> IBKR.

### The per-integration loop (same every time)
For integration X:
1. New session, /clear. Tell Claude to read docs/agent/integrations.md section for X.
2. Plan Mode: OAuth/token setup + the cron route that writes cache_X in Supabase.
3. Implement auth + the refresh/fetch job. Trigger it manually, confirm rows land in
   Supabase (see running-locally.md).
4. Build the widget that reads cache_X and drops into the shell's slot.
5. `pnpm verify`. Tick the box in PROGRESS.md. Commit. Done - move on next session.

### Integration-specific reminders
- Notion: the AI-description call is a Groq API call (llama-3.1-8b-instant),
  server-side, using your existing Groq key. OpenAI-compatible SDK, just point the
  base URL at https://api.groq.com/openai/v1.
- TickTick: Open API or MCP - both work now. Don't reuse the old "no MCP" assumption.
- Fair: build the 3 tables + contribution form + editable DCA settings + a best-effort
  price fetch WITH a manual price-override field. The fund is 5140785.
- IBKR: use the Flex Web Service path (token + scheduled statement), not the live
  gateway, unless a needed field is missing. Build it as a separate job. Do this last.

---

## Phase 4 - Ship
1. Push to GitHub, import the repo into Vercel.
2. Set all env vars from running-locally.md in Vercel project settings.
3. Configure Vercel cron for the refresh routes (schedules in ARCHITECTURE.md).
4. Verify each widget shows live cached data in production.
5. Final dark-mode + RTL polish on the deployed build.
6. Tick the Ship section in PROGRESS.md.

---

## If you only remember five things
1. Design in light + dark + RTL up front.
2. Tokens in DESIGN_BRIEF.md keep design and code in sync.
3. Cache in Supabase; never call APIs on render.
4. One integration per session, /clear, Plan Mode, verify, update PROGRESS.
5. Fair = public fund price + manual contributions; IBKR = Flex, not gateway.
