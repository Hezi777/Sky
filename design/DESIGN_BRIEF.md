# Design Brief - Personal Dashboard (for Claude Design)

Direction: light base with a dark-mode toggle, Coursue-style warmth (hero greeting with
memoji), blue accent, clean rounded cards on white space. Personal daily-glance tool,
single user (me). Hebrew text appears in some fields - layout must tolerate RTL.

Attach all three reference screenshots when you start, then paste the OPENING PROMPT.

---

## OPENING PROMPT (paste first, with the 3 screenshots attached)

Create a personal dashboard web app, light theme with a dark-mode toggle.

Audience: just me - a single-user daily-glance dashboard, not a corporate product.
Vibe: warm and friendly like the third screenshot (Coursue) - it has a hero greeting
card with a memoji and "Good Morning Jason" plus a circular progress ring. I want that
warmth. Borrow the clean stat-card discipline and grouped sidebar from the second
screenshot (Nexus). Do NOT use the dark neon style of the first screenshot.

Accent color: blue. Everything secondary in neutral grey. Single accent only.

Layout:
- Left sidebar: app logo at top, nav grouped into sections (OVERVIEW, FINANCE, TOOLS),
  my profile pinned at the bottom.
- Top bar: search field, current date/time, a notifications bell, my avatar.
- Main area, card grid:
  1. Hero greeting card (top-left, wider): memoji avatar, "Good morning Hen", and a
     short line (e.g. a streak or what's on today). Soft blue gradient background.
  2. Today's calendar - a few time-stamped events.
  3. Today's tasks - a short checklist (from TickTick).
  4. Portfolio (Interactive Brokers) - total value, day change with up/down %, and a
     small donut of allocation.
  5. Savings (Fair) - a DCA tracker card: current value (large), total contributed,
     and gain/loss as a colored pill, plus a small "+ add contribution" action and an
     editable DCA setting (amount/frequency). Show a "price updated" date.
  6. GitHub - a few repos each with a build-status pill (pass/fail) and open-PR count.
  7. Spotify - last played track with cover art.
  8. Notion quick-add - a text input "Paste a link..." with an Add button; this is an
     AI feature that auto-writes a description.

Rounded cards, generous spacing, soft shadows. Friendly but not childish. Make the hero
card feel personal. Generate the full dashboard shell first; I'll refine each card next.

---

## ITERATION PROMPTS (use after the shell exists, one at a time)

- Hero card: "Make the greeting card warmer - softer blue gradient, bigger memoji, and a
  small fire/streak element like the Coursue reference. Keep text left-aligned."
- Portfolio: "In the portfolio card, show total value large, day change as a colored
  pill (green up / red down), and a compact donut for allocation. Blue-family palette."
- Fair tracker: "Make the Fair savings card show current value large, total contributed
  smaller beneath, gain/loss as a green/red pill, an '+ Add contribution' button, and a
  small editable DCA line like '300 NIS monthly'. Include a faint 'price updated today'."
- Tasks: "Make tasks look like a friendly checklist with round checkboxes, not a table."
- GitHub: "Show each repo as a row with a small status dot (green pass, red fail) and a
  PR count badge. Keep it compact."
- Spotify: "Last-played card: cover art on the left, track + artist on the right, subtle."
- Dark mode: "Show me the dark-mode version of the whole dashboard. Keep blue accent,
  use deep neutral greys, not pure black. Make sure contrast passes accessibility."
- RTL check: "Some labels will be Hebrew (right-to-left). Show the cards with a couple of
  Hebrew labels so I can confirm the layout doesn't break."
- Self-critique: "Review this design for contrast ratios, information hierarchy, and
  usability. What would you change?"

---

## DESIGN TOKENS (so the handoff matches the Tailwind 4 build)

Give these to Claude Design if it asks for specifics, and reuse them in the @theme block
in the Next.js app so design and code stay in sync.

- Accent (blue): a mid blue around #2563EB, lighter #60A5FA, dark #1E40AF
- Neutrals: near-white bg #F8FAFC, card #FFFFFF, borders #E2E8F0, text #0F172A, muted #64748B
- Dark mode: bg #0B1220, card #111827, border #1F2937, text #E5E7EB
- Status: success #16A34A, danger #DC2626, pending #D97706
- Radius: cards ~16px, inputs ~10px
- Shadow: soft, low-opacity, no hard edges
- Type: one clean sans (Inter or similar); large friendly numbers for the stat values

---

## HANDOFF
When the layout is approved, use Claude Design's "hand off to Claude Code" bundle. It
ships the design + context in one instruction. Point it at this repo so it picks up
CLAUDE.md, docs/PRD.md, and docs/ARCHITECTURE.md - the build is already scoped there.
Then build by reading the cached Supabase data per docs/ARCHITECTURE.md (no live API
calls on render).
