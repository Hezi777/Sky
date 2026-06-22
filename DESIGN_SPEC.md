# Sky Native — Design Spec

One unified liquid-glass design language for the macOS/iOS dashboard widgets.
Derived from the reference widgets (IBKR/Portfolio, Fair/Fund, Countdown, Tasks)
and the shared `Theme.swift` container. **Styling & layout only** — no data, state,
or behavior changes.

## Tokens (canonical — all in `Theme.swift`)

| Token | Value | Use |
|---|---|---|
| `Theme.gap` | 16 | Grid gutter / page horizontal padding |
| `Theme.cardPadding` | 18 | Outer padding inside every `Card` |
| `Theme.cardRadius` | 22 (continuous) | Card corner radius |
| `Theme.contentSpacing` | **12** | Every widget's content VStack spacing |
| `Theme.sectionSpacing` | **6** | Section label → content |
| `Theme.innerRadius` | **12** | Nested containers (list/repo rows) |
| `Theme.mediaRadius` | **8** | Media thumbnails (album art) |

## Card surface (unchanged — cards stay opaque)

`CardBg @ 0.92` fill · `white@0.06` 0.5pt strokeBorder · shadow `black@0.18 r14 y6`
· clipShape r22 continuous. Provided by `Card` / `AsyncCard` — do not re-implement
per widget.

## Glass material (scope: hero/header chrome ONLY)

Apply the existing `glassSurface()` modifier (real `.glassEffect` on macOS/iOS 26,
`.ultraThinMaterial` fallback) to the **hero / top chrome only**. Widget cards remain
opaque `CardBg@0.92`. Do not switch any widget `Card` to glass.

## Header

`CardHeader`: SF Symbol 13pt `.medium` in 18×18 frame, tinted `Theme.accent`;
title `.subheadline.weight(.semibold).foregroundStyle(.secondary)`; HStack spacing 7;
optional trailing accessory in the dedicated slot (use it — do not overlay buttons
on the card).

## Typography

| Role | Style |
|---|---|
| Widget title | `.subheadline.weight(.semibold)` `.secondary` |
| Primary value | `.rounded`, 28–54pt, `.monospacedDigit()` |
| Body row text | `.subheadline.weight(.medium/.semibold)` |
| Caption | `.caption` (often `.secondary`) |
| **Section header** | `.caption2.weight(.semibold)` + `.textCase(.uppercase)`, **no extra tracking** |
| Micro/data labels | `.system(size: 8–9)` |

## Color

`Theme.accent` (`SkyPrimary`) for all header tints and accents; `.green`/`.red` for
positive/negative; `.secondary`/`.tertiary` for de-emphasized text.
**Spotify** keeps `.green` tint — documented brand exception.

---

## Per-widget punch list

| Widget | Changes |
|---|---|
| **GitHub** | Width-adaptive heatmap via `GeometryReader` — compute `cell = (width − labelWidth − gaps) / cols` instead of hardcoded 11 (fixes the clip/overflow that reads as a Weather overlap); apply same to the month-label row; content spacing 16 → `contentSpacing` (12); move contribution count into `CardHeader` trailing accessory; inner row radius → `innerRadius` |
| **Calendar** | Content/day-group spacing 14 → `contentSpacing` (12); day-section header `.caption` → `.caption2.weight(.semibold)`, drop `tracking(0.6)` |
| **Spotify** | Section header `.caption.medium` → `.caption2.weight(.semibold)`; drop stray `.padding(4)`; keep `.green` tint |
| **Stocks** | Content spacing 8 → `contentSpacing` (12); move edit pencil into `CardHeader` trailing accessory (no card overlay) |
| **Strava** | Content spacing 10 → `contentSpacing` (12) |
| **WidgetPlaceholder** | Add `tint: Theme.accent` to its `CardHeader` |
| **Hero / top chrome** | Apply `glassSurface()` to the hero header chrome only |
| **Weather** | No change — `.thin` 48pt temp kept as intentional |
| **IBKR / Fair / Countdown / Tasks / Quote / Reading** | Reference / already-clean — no change |

## Constraints

Styling & layout only. No state machine, data/logic, Electron, new deps, or folder
changes. Reference widgets untouched. `glassSurface()` limited to hero chrome.
