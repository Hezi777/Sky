# Sky Native Design

Sky uses one restrained native design language: opaque information cards over atmospheric backgrounds, with Liquid Glass reserved for top-level chrome.

## Tokens

All view geometry and color comes from `native/Sky/DesignSystem/Tokens.swift`.

- Page gutter: 16
- Card gap: 12
- Section gap: 30
- Card padding: 18
- Content spacing: 12
- Section spacing: 6
- Card radius: 22, continuous
- Nested radius: 12
- Media radius: 8
- Card surface: `CardBg` at 0.92, white stroke at 0.06/0.5pt, black shadow at 0.18 with radius 14 and y-offset 6
- Semantic color roles: accent, positive, negative, warning, caution, info, neutral, and secondary text

Do not introduce literal spacing, radius, size, or color values in views. Add a named token when the system lacks an exact value.

## Surfaces

`WidgetShell` is the standard widget container. It composes the opaque `Card` surface, `CardHeader`, and widget content. Async widgets use `AsyncCard`, which composes `WidgetShell` and owns loading, empty, error, and retry states.

`GlassCard` and `glassSurface()` are for hero and top-level chrome only. Widgets remain opaque. Direct `.glassEffect` calls outside `native/Sky/DesignSystem` are prohibited. Put related glass elements inside one `GlassEffectContainer` so the system can merge their material correctly.

## Color and type

Tint communicates meaning; it is not decoration. Use the accent for app identity, positive/negative for direction, warning/caution for status, and provider brand color only when identity requires it, such as Spotify green. Prefer semantic system foreground styles for hierarchy and accessibility.

Use the named type roles in `Tokens.Font`. Primary values may use the rounded, monospaced-digit helper with a value-specific size; standard labels and rows use the fixed semantic roles.
