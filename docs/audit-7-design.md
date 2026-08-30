# Audit 7 — Design/Visual Layer (legacy-web)

Scope: `legacy-web/` Next.js frontend (`app/globals.css`, `components/`, `hooks/`, `lib/`). Read-only audit, no source changes made. `native/` (SwiftUI) and `electron/` were skimmed for context only.

Context: `docs/DESIGN.md` documents a real, enforced token system for the **native** app (`native/Sky/DesignSystem/Tokens.swift` — page gutter 16, card gap 12, card radius 22, etc., with a rule against literal values in views). No equivalent document, token file, or enforcement exists for `legacy-web`. The two surfaces are not sharing a design system in any meaningful way.

## 1. Design tokens (`app/globals.css :root`)

**Finding:**
- Colors: light theme — background `#f0f0f3`, foreground `#1a1a1e`, card `#ffffff`, primary `#2563eb`, secondary/muted/accent all `#e8e8ec`, border/input `#d8d8de`, destructive `#dc2626`. Dark theme (`.dark`) — background `#050505`, foreground `#ededed`, card `#111113`, primary `#3b82f6`, secondary/muted/accent `#1a1a1c`, border `#26262a`, destructive `#e5484d`.
- Sidebar tokens (dark-only surface, used in both themes): `#0b1220`/`#080808` bg, `#94a3b8`/`#9a9aa0` foreground, accent `#1f2937`/`#1a1a1c`.
- Chart colors: 5 hues per theme (blue, teal/blue, violet/blue, amber, rose).
- GitHub heatmap scale: 5 steps per theme (light: `#e8edf3` → `#176b33`; dark: `#1b1c1f` → `#39d353`).
- Ambient glow colors (used by `sky-ambient.tsx`): `--bg-glow-primary #2563eb`, `--bg-glow-secondary #1d4ed8`/`#0f3a8a`, `--bg-glow-depth #0f172a`/`#030303`.
- Radius: single base `--radius: 0.75rem` (12px), with derived scale `sm .6× / md .8× / lg 1× / xl 1.4× / 2xl 1.8× / 3xl 2.2× / 4xl 2.6×` — i.e. 7.2px, 9.6px, 12px, 16.8px, 21.6px, 26.4px, 31.2px. Only one radius value is actually set; the rest is math off it, which is coherent.
- Fonts: `--font-apple-sans` = `"SF Pro Text", "SF Pro Display", -apple-system, BlinkMacSystemFont, "Helvetica Neue", Arial, sans-serif`; `--font-apple-mono` = `"SF Mono", "SFMono-Regular", ui-monospace, Menlo, Monaco, Consolas, monospace`. `--font-heading` is aliased to the same sans stack (no distinct heading face). No shadow tokens exist in `:root` — every shadow in the app is a one-off inline arbitrary value (see §3/§6).

**Inconsistency:**
- `--font-heading` exists as a named token but is literally `var(--font-apple-sans)` — a token with no distinct value, used in `components/ui/card.tsx:41` and `components/ui/dialog.tsx:125`.
- No `--shadow-*` tokens despite shadows appearing repeatedly as bespoke `rgba()` stacks (`components/layout/header.tsx:94-95`, `:113-114`). Radius has a token scale; shadow does not.
- No spacing scale token exists at all — spacing is 100% raw Tailwind utilities plus ad hoc arbitrary values (§3).

## 2. Type scale

**Finding:** Actual `text-*` sizes used across the frontend: `text-xs`, `text-sm`, `text-base`, `text-lg`, `text-xl`, `text-2xl`, `text-3xl`, `text-4xl`, `text-5xl`, plus arbitrary `text-[9px]`, `text-[10px]`, `text-[11px]`, `text-[0.8rem]`. Weights used: `font-normal`, `font-medium`, `font-semibold`, `font-bold`. Leading: `leading-none`, `leading-tight`, `leading-snug`, `leading-relaxed`, `leading-6`, `leading-3`, `leading-4`.

Dominant pattern: `text-xs` and `text-sm` (both ~40+ uses) carry almost all body/label copy. `text-sm font-medium` is the de facto default for widget titles (inherited from `CardTitle`'s base style at `components/ui/card.tsx:41`, which is actually `text-base leading-snug font-medium`, not `text-sm`).

**Inconsistency (single-use / one-off sizes):**
- `text-[9px]` — `components/widgets/ticktick-widget.tsx:173` (checkbox count badge). Only occurrence of 9px anywhere.
- `text-[0.8rem]` — `components/ui/button.tsx:26` (sm button). Duplicates `text-xs` (0.75rem) territory with a slightly different, unexplained value.
- `text-5xl` — `components/hero-zone.tsx:118` only place in the app text goes above `text-4xl`.
- `leading-3` / `leading-4` — `components/ui/git-hub-calendar.tsx:122` / `:109` only; nowhere else does the app use numeric leading below `leading-6`.
- `leading-relaxed` — `components/hero-zone.tsx:126,130` only; every other paragraph in the app uses `leading-tight`/`leading-snug`/`leading-none`/`leading-6` (a fixed px value), so hero-zone uses a fourth, unrelated leading convention.
- CardTitle sizing/weight forks three ways across widgets that all sit in visually identical Card headers:
  - default (`text-base font-medium`, inherited, no override) — `spotify-widget.tsx`, `github-heatmap.tsx`, `ibkr-widget.tsx`, `ticktick-widget.tsx`, `github-repos.tsx`, `fair-widget.tsx`.
  - `text-sm font-semibold` — `next-task.tsx:94`, `active-projects.tsx:151`.
  - `text-sm font-medium` — `calendar-widget.tsx:305`, `resource-quick-add.tsx:46`.
  Same UI role (widget card title), three different size/weight pairs with no evident reason.

## 3. Spacing — arbitrary values

**Finding (every arbitrary bracketed spacing/size value, file + line):**
- `components/hero-zone.tsx:122` — `min-h-[1.75rem]`
- `components/dashboard.tsx:29` — `xl:grid-rows-[1fr_auto]`
- `components/memoji-picker.tsx:49` — `text-[11px]`
- `components/theme-toggle.tsx:23` — `size-[18px]`
- `components/theme-toggle.tsx:24` — `size-[18px]`
- `components/settings-dialog.tsx:35` — `size-[17px]`
- `components/ui/card.tsx:28` — `grid-cols-[1fr_auto]`, `grid-rows-[auto_auto]` (data-attr driven)
- `components/ui/tooltip.tsx:59` — `translate-y-[calc(-50%-2px)]`, `rounded-[2px]`
- `components/ui/scroll-area.tsx:21` — `rounded-[inherit]`, `transition-[color,box-shadow]`, `focus-visible:ring-[3px]`
- `components/ui/badge.tsx:8` — `focus-visible:ring-[3px]`
- `components/ui/git-hub-calendar.tsx:140,160` — `rounded-[4px]`
- `components/ui/button.tsx:25-26,30` — `rounded-[min(var(--radius-md),10px)]`, `rounded-[min(var(--radius-md),12px)]`, `text-[0.8rem]`
- `components/widgets/github-heatmap.tsx:81` — `h-[150px]`
- `components/widgets/github-heatmap.tsx:98` — `xl:min-h-[11.25rem]`
- `components/layout/header.tsx:94-95` — `shadow-[0_10px_24px_rgba(0,0,0,0.16),0_0_32px_rgba(0,0,0,0.08)]` and 3 sibling one-off shadow stacks
- `components/layout/header.tsx:113-114` — `dark:bg-[#131315]/78`, `dark:bg-[#131315]/62`
- `components/layout/header.tsx:118` — full inline radial/linear gradient background as an arbitrary value
- `components/widgets/spotify-widget.tsx:26` — `gap-[2px]`
- `components/widgets/spotify-widget.tsx:30` — `w-[3px]`, `bg-[#1DB954]`
- `components/widgets/spotify-widget.tsx:52,123,146` — `text-[#1DB954]` (3×, not tokenized despite being a repeated brand color)
- `components/widgets/ibkr-widget.tsx:248` — `lg:grid-cols-[220px_1fr]`
- `components/widgets/ticktick-widget.tsx:125` — `rounded-[4px]`
- `components/widgets/ticktick-widget.tsx:173` — `text-[9px]`
- `components/widgets/calendar-widget.tsx:176` — `grid-cols-[3.9rem_1fr]`, `sm:grid-cols-[4.2rem_1fr_auto]`
- `components/widgets/calendar-widget.tsx:185,193` — `text-[10px]`
- `components/widgets/calendar-widget.tsx:200` — `-left-[5px]`
- `components/widgets/calendar-widget.tsx:209` — `text-[10px]`
- `components/widgets/calendar-widget.tsx:223,230` — `text-[11px]`
- `components/widgets/calendar-widget.tsx:266` — `sm:grid-cols-[4.8rem_1fr]`
- `components/widgets/calendar-widget.tsx:268` — `tracking-[0.16em]`
- `components/widgets/fair-widget.tsx:459,534` — `text-[11px]`

**Inconsistency:** Pixel-value arbitrary text sizes (`text-[9px]`, `text-[10px]`, `text-[11px]`) appear in 4 different widgets as substitutes for what should be one shared "micro label" scale step below `text-xs` (12px) — instead each widget picked its own px value independently. Grid-template arbitrary values (`3.9rem`, `4.2rem`, `4.8rem`, `220px`) are each single-use, hand-tuned per widget rather than derived from a shared column token.

## 4. Layout containers

**Finding:**
- The whole app is a single route (`app/page.tsx` → `Dashboard`); no other pages exist, so there's no cross-page container inconsistency to compare — only cross-widget.
- Outer page padding: `app/layout.tsx:40` — `px-4 pb-8 sm:px-6` on `<main>`. No `max-width` is ever applied to the page shell — the dashboard grid stretches full viewport width at all sizes.
- Dashboard grid (`components/dashboard.tsx:26-55`): `grid-cols-1 gap-3 sm:grid-cols-6 xl:grid-cols-12`, with per-section spans (`sm:col-span-6`, `xl:col-span-12/8/4/5/3`) and one nested nonstandard template `xl:grid-cols-[minmax(0,1.08fr)_minmax(22rem,0.92fr)]`.
- Widget cards: `rounded-2xl` is the standard for 11 of 12 widget `<Card>` wrappers (`ui/card.tsx:15` base is also `rounded-2xl` via `rounded-xl` on the base... actually the shared `Card` base sets `rounded-t-2xl` header radius; each widget re-applies `rounded-2xl` at the outer `<Card>` explicitly, which is redundant since it's already the sensible default but every widget repeats it by hand).
- `max-w-*` usage is sparse and purpose-specific: `hero-zone.tsx:117` (`max-w-lg`, hero copy), `settings-dialog.tsx:38` (`sm:max-w-md`), tooltip/dialog internals (`max-w-xs`, `max-w-[calc(100%-2rem)]`, `sm:max-w-sm`), `ticktick-widget.tsx:77` (`max-w-20`, single tag truncation), `calendar-widget.tsx:237` (`max-w-xs` tooltip). These are all local, not part of a page-level container system.

**Inconsistency:**
- `greeting-card.tsx:81` uses `rounded-3xl` on its `<Card>` — the only widget-level card that breaks the `rounded-2xl` convention used everywhere else. (Also dead code — see Verdict.)
- No page-level `max-width`/centering exists anywhere; on very wide viewports the 12-col dashboard grid has no upper bound, unlike the native app which has an explicit page-gutter/section-gap token system (`docs/DESIGN.md`).

## 5. Responsive breakpoints per component

**Finding — breakpoint prefixes actually used, by file (count of `sm:`/`md:`/`lg:`/`xl:`/`2xl:` occurrences):**
- `components/dashboard.tsx` — 18 (`sm:`, `xl:`) — heaviest responsive file, the whole grid depends on it.
- `components/widgets/greeting-card.tsx` — 8 (dead code, not rendered — see Verdict)
- `components/widgets/calendar-widget.tsx` — 5 (`sm:`)
- `components/layout/header.tsx` — 5 (`sm:`) (dead code — not imported anywhere)
- `components/hero-zone.tsx` — 4 (`sm:`, `lg:`)
- `components/widgets/github-heatmap.tsx` — 3 (`xl:`)
- `components/ui/dialog.tsx` — 3 (`sm:`)
- `components/cloud-avatar.tsx` — 3
- `components/widgets/ibkr-widget.tsx` — 2 (`lg:`)
- `components/ui/button.tsx` — 2
- `components/settings-dialog.tsx`, `components/ui/input.tsx`, `app/layout.tsx` — 1 each

**Flag — zero responsive classes at all** (every other `.tsx` file under `app/` and `components/`, notably every widget except `calendar-widget.tsx` and `ibkr-widget.tsx`): `active-projects.tsx`, `fair-widget.tsx`, `github-repos.tsx`, `next-task.tsx`, `resource-quick-add.tsx`, `spotify-widget.tsx`, `ticktick-widget.tsx`, plus all of `components/ui/*` except `dialog.tsx`, `button.tsx`, `input.tsx`. These widgets render identically from a phone-width viewport to a 4K monitor; only the *grid placement* around them in `dashboard.tsx` changes column span. Internal widget content (text truncation, icon sizing, row density) never adapts — small widgets that get squeezed into a narrow grid column on mobile (`sm:col-span-6` at 1-col-equivalent width) have no internal breakpoint handling for that width change.

## 6. Motion

**Finding — all transition/animation usage:**
- CSS keyframe animations defined in `globals.css:141-163`: `fade-in-up` (0.3s, `cubic-bezier(0.22,1,0.36,1)`), `fade-in` (0.25s, `ease`), `scale-in` (0.25s, `cubic-bezier(0.22,1,0.36,1)`). Applied via `.animate-fade-in-up` / `.animate-fade-in` / `.animate-scale-in` utility classes — used across 6 widgets for entrance animation.
- Tailwind `duration-*` distribution: `duration-100` ×3, `duration-150` ×11, `duration-200` ×14, `duration-500` ×2, `duration-700` ×1. No `duration-300`/`duration-400`/`duration-1000` etc. — reasonably tight cluster around 150-200ms, which is good, but the outliers (500ms, 700ms) are both in the dead `header.tsx` file.
- Named easing only appears twice: `ease-in-out` (`spotify-widget.tsx:33`) and one raw inline `cubic-bezier(0.175, 0.885, 0.32, 2.2)` (`header.tsx:98`, a spring-like overshoot curve, again dead code). Every other transition uses Tailwind's default easing (`ease` / no explicit easing class), so there's no consistent named easing token — durations are the only thing that's roughly systematic.
- `framer-motion` is used directly (not via CSS) in `hero-zone.tsx` (typewriter cursor blink, `duration: 0.9, repeat: Infinity`) and `header.tsx` (`duration: 0.45, ease: [0.22, 1, 0.36, 1]`) — a second, parallel animation system alongside the CSS keyframes/Tailwind transitions, used in only 2 files.

**Inconsistency:**
- Three overlapping motion systems coexist with no clear division of labor: Tailwind `transition-*`/`duration-*` utilities (majority), custom CSS `@keyframes` + `.animate-*` utilities (entrance effects), and `framer-motion` (2 files only, one of which is dead code).
- The one hand-written cubic-bezier overshoot easing (`header.tsx:98`) exists nowhere else in the codebase and belongs to an unused component.

## 7. Fonts

**Finding:**
- No `next/font` import anywhere in the project (`grep -rn "next/font"` returns nothing) and no `@font-face` in `globals.css`. All typography relies entirely on the system font stack declared in `--font-apple-sans` / `--font-apple-mono` (SF Pro / SF Mono with generic fallbacks) — i.e., no web font is actually loaded; this is a "look like macOS" strategy, not a loaded typeface.
- `--font-sans` and `--font-heading` are both mapped to `--font-apple-sans` in the `@theme inline` block (`globals.css:10,12`) — there is no distinct heading typeface, despite a dedicated `font-heading` utility class existing and being used (`ui/card.tsx:41`, `ui/dialog.tsx:125`).
- `--font-mono` (`--font-apple-mono`) is declared but never referenced by any `font-mono` utility class anywhere in `components/` or `app/` — dead token.
- `body` in `globals.css:174-178` sets `font-family` a second time, redundantly, with a slightly different fallback order (`-apple-system, "SF Pro Text", "SF Pro Display", var(--font-apple-sans), sans-serif`) than the `--font-apple-sans` variable itself (`"SF Pro Text", "SF Pro Display", -apple-system, ...`) — two different orderings of the same three fonts defined in two places.

**Inconsistency:** `font-heading` and `font-mono` are both tokens/utilities that exist in the system but are either aliases with no distinct value (`font-heading`) or entirely unused (`font-mono`) — tokens declared for a distinction the CSS never actually makes.

---

## Verdict

There's a thin, mostly-coherent skeleton (one radius token driving a derived scale, a tight cluster of transition durations, a real light/dark color palette) wrapped in a much larger pile of one-off decisions layered on top of it. Three findings make the "system" claim hard to sustain:

1. **Two abandoned components carry their own separate design language.** `components/layout/header.tsx` (liquid-glass filter, framer-motion, a hand-tuned overshoot `cubic-bezier(0.175, 0.885, 0.32, 2.2)`, `duration-500`/`duration-700`) and `components/layout/sidebar.tsx` are never imported by anything — the live app uses `components/bottom-bar.tsx` instead, a completely different, much simpler pattern. `components/widgets/greeting-card.tsx` and `components/glass-card.tsx` are likewise unused and each break the live conventions they'd otherwise have to follow (`rounded-3xl` vs. the standard `rounded-2xl`). A third of what looks like "the design system" when grep'ing the codebase is actually dead code the live UI doesn't use.
2. **No spacing or shadow token scale exists**, only a radius scale. Every shadow is a bespoke inline `rgba()` stack, and every micro-text size below 12px (`text-[9px]`, `text-[10px]`, `text-[11px]`) and every custom grid-column width (`3.9rem`, `4.2rem`, `4.8rem`, `220px`) was picked independently per widget rather than drawn from a shared scale — this is the definition of one-off decisions, not a system.
3. **Responsive design is applied to grid placement only, not to component internals.** 9 of 12 widgets and nearly all of `components/ui/*` ship zero responsive classes; only the outer grid (`dashboard.tsx`) adapts. Widget card titles fork into three unexplained size/weight combinations for the same semantic role.

The native SwiftUI app (`docs/DESIGN.md`) has an actual enforced token file and a written rule against literal values in views. `legacy-web` has none of that discipline — it has good instincts (the radius scale, the duration clustering) but no enforcement, and the presence of un-imported components with contradictory conventions shows nobody is auditing for drift as the app evolves.
