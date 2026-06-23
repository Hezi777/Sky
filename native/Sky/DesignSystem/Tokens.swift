import SwiftUI

// Sky design tokens — the single source of truth for spacing, radius, type, and
// color. Calm, native, Apple-Health-adjacent.
//
// DESIGN SYSTEM RULES (enforced by convention in Phase 1, by SwiftLint later):
// • No raw spacing / radius / color literals in Views — reference a token here.
// • No `.glassEffect` outside DesignSystem/ — use GlassCard / glassSurface().
// • Let the system handle accessibility: prefer semantic foreground styles
//   (.secondary/.tertiary) and Dynamic Type fonts; never hard-code text colors
//   or fixed point sizes for body text in Views.
//
// Colors are Assets.xcassets-backed (light/dark via luminosity) so dark mode is
// automatic.

enum Tokens {

    // MARK: Spacing

    /// Grid gutter / page horizontal padding.
    static let gap: CGFloat = 16
    /// Gap between cards within a section. Tighter than `gap` (the page margin)
    /// so cards read as one connected group, not scattered tiles.
    static let cardGap: CGFloat = 12
    /// Gap between whole sections. Larger than `cardGap` so sections read as
    /// distinct grouped bands (visual hierarchy), not one flat list of tiles.
    static let sectionGap: CGFloat = 30
    /// Outer padding inside every card surface.
    static let cardPadding: CGFloat = 18
    /// Standard spacing inside a card's content VStack.
    static let contentSpacing: CGFloat = 12
    /// Spacing between a section label and its content (sub-sections).
    static let sectionSpacing: CGFloat = 6
    /// Micro-spacing for dense row internals — inline icon↔text gaps, badge
    /// padding, chart legends. `tight` < `snug` < `sectionSpacing`.
    static let zeroSpacing: CGFloat = 0
    static let microSpacing: CGFloat = 1
    static let equalizerSpacing: CGFloat = 1.5
    static let extraTight: CGFloat = 2
    static let badgePadding: CGFloat = 3
    static let tight: CGFloat = 4
    static let compact: CGFloat = 5
    static let headerSpacing: CGFloat = 7
    static let snug: CGFloat = 8
    static let rowSpacing: CGFloat = 10
    static let wideSpacing: CGFloat = 14
    static let editorPadding: CGFloat = 24
    static let dashboardBottomPadding: CGFloat = 32
    static let heroTopPadding: CGFloat = 36

    // MARK: Dashboard layout

    static let dashboardMaxWidth: CGFloat = 1500
    static let dashboardGridBreakpoint: CGFloat = 480
    // Narrow columns so a 1×1 "small" tile reads near-square (Apple-like): a
    // ~210pt column against the ~190pt row unit. Medium (2 cols) ≈ 2:1, large
    // (2×2) ≈ square — matching the WidgetFamily proportions.
    static let dashboardGridTarget: CGFloat = 210
    static let dashboardGridMinimum: CGFloat = 180
    static let dashboardGridMaxColumns = 6
    /// Height of one grid row unit. Sized so a single-column tile is roughly
    /// square against `dashboardGridTarget`. Tiles spanning multiple rows get
    /// `rows * dashboardRowUnit + (rows-1) * cardGap` total height.
    static let dashboardRowUnit: CGFloat = 190

    // MARK: Radius

    /// Card corner radius (continuous).
    static let cardRadius: CGFloat = 22
    /// Corner radius for nested containers inside a card (e.g. repo/list rows).
    static let innerRadius: CGFloat = 12
    /// Corner radius for media thumbnails (album art, etc.).
    static let mediaRadius: CGFloat = 8
    /// Corner radius for small chart elements (bars, pills).
    static let barRadius: CGFloat = 3
    static let hairlineRadius: CGFloat = 0.5
    static let tinyRadius: CGFloat = 1.5
    static let smallRadius: CGFloat = 4
    static let compactRadius: CGFloat = 6

    // MARK: Card surface (consumed by Card / WidgetShell — never re-implemented per widget)

    /// Opaque card fill. Widget cards stay opaque; glass is hero-chrome only.
    static let cardFill = Color("CardBg").opacity(0.92)
    /// Hairline border that lifts the card off the background.
    static let cardStroke = Color.white.opacity(0.06)
    static let cardStrokeWidth: CGFloat = 0.5
    static let cardShadowColor = Color.black.opacity(0.18)
    static let cardShadowRadius: CGFloat = 14
    static let cardShadowY: CGFloat = 6

    // MARK: Semantic colors

    /// Accent — Sky blue, matches the web app's --primary (light/dark via asset).
    static let accent = Color("SkyPrimary")
    /// Positive / negative meaning (gains, losses, up/down).
    static let positive = Color.green
    static let negative = Color.red
    static let warning = Color.orange
    static let caution = Color.yellow
    static let info = Color.blue
    static let neutral = Color.gray
    /// De-emphasized text. Semantic + accessibility-aware; pair with
    /// `.foregroundStyle(.secondary)` / `.tertiary` in Views where a ShapeStyle
    /// is needed.
    static let textSecondary = Color.secondary

    /// Ordered chart palette, mirrors the web --chart-1…5 (adapts light/dark).
    static let chartPalette: [Color] = [
        Color("Chart1"), Color("Chart2"), Color("Chart3"), Color("Chart4"), Color("Chart5"),
    ]

    /// GitHub contribution scale: index 0 = empty, 1…4 = increasing intensity.
    static let githubLevels: [Color] = [
        Color("GithubEmpty"), Color("Github1"), Color("Github2"), Color("Github3"), Color("Github4"),
    ]

    /// Provider-defined Google Calendar palette keyed by Calendar API color ID.
    static let calendarColors: [String: Color] = [
        "1": Color(red: 0.475, green: 0.525, blue: 0.796),
        "2": Color(red: 0.200, green: 0.714, blue: 0.475),
        "3": Color(red: 0.557, green: 0.141, blue: 0.667),
        "4": Color(red: 0.902, green: 0.486, blue: 0.451),
        "5": Color(red: 0.965, green: 0.749, blue: 0.149),
        "6": Color(red: 0.957, green: 0.318, blue: 0.118),
        "7": Color(red: 0.012, green: 0.608, blue: 0.898),
        "8": Color(red: 0.380, green: 0.380, blue: 0.380),
        "9": Color(red: 0.247, green: 0.318, blue: 0.710),
        "10": Color(red: 0.043, green: 0.502, blue: 0.263),
        "11": Color(red: 0.835, green: 0.000, blue: 0.000),
    ]

    static func chartColor(_ index: Int) -> Color { chartPalette[index % chartPalette.count] }

    // MARK: Component sizes

    enum Size {
        static let hairlineBar: CGFloat = 2.5
        static let eventBar: CGFloat = 3
        static let progressBar: CGFloat = 4
        static let legendDot: CGFloat = 7
        static let heatmapCell: CGFloat = 11
        static let compactControl: CGFloat = 12
        static let symbolBox: CGFloat = 18
        static let activityIcon: CGFloat = 22
        static let stockSparklineHeight: CGFloat = 22
        static let recentArtwork: CGFloat = 32
        static let bookCoverWidth: CGFloat = 36
        static let progressRing: CGFloat = 38
        static let emptyStateHeight: CGFloat = 44
        static let calendarTimeColumn: CGFloat = 50
        static let bookCoverHeight: CGFloat = 52
        static let artwork: CGFloat = 56
        #if os(macOS)
        static let heroCharacter: CGFloat = 148
        static let statusCharacter: CGFloat = 84
        static let placeholderCharacter: CGFloat = 56
        static let skyAmbientHeight: CGFloat = 500
        #else
        static let heroCharacter: CGFloat = 118
        static let statusCharacter: CGFloat = 72
        static let placeholderCharacter: CGFloat = 48
        static let skyAmbientHeight: CGFloat = 400
        #endif
        static let weatherChartHeight: CGFloat = 72
        static let portfolioChart: CGFloat = 108
        #if os(macOS)
        static let heroMinHeight: CGFloat = 270
        #else
        static let heroMinHeight: CGFloat = 220
        #endif
        static let editorMinHeight: CGFloat = 250
        static let editorMinWidth: CGFloat = 320
        static let heroTextMaxWidth: CGFloat = 420
        static let rootMinHeight: CGFloat = 560
        static let settingsWidth: CGFloat = 420
        static let rootMinWidth: CGFloat = 720
    }

    // MARK: Type ramp

    /// Named font roles from the design spec. Use these instead of `.font(.system(size:))`
    /// for everything except the large rounded "primary value" displays.
    enum Font {
        /// Widget header title.
        static let widgetTitle: SwiftUI.Font = .subheadline.weight(.semibold)
        /// Standard body row text.
        static let bodyRow: SwiftUI.Font = .subheadline.weight(.medium)
        /// Emphasized body row text.
        static let bodyRowStrong: SwiftUI.Font = .subheadline.weight(.semibold)
        /// Caption / supporting text.
        static let caption: SwiftUI.Font = .caption
        /// Uppercased sub-section header.
        static let sectionHeader: SwiftUI.Font = .caption2.weight(.semibold)
        /// Micro data labels (heatmap weekday/month, chart ticks).
        static let microLabel: SwiftUI.Font = .system(size: 9)

        /// Large rounded, monospaced-digit "primary value" display (28–54pt).
        /// Variable by design — temperature, countdown days, P&L all differ.
        static func primaryValue(size: CGFloat, weight: SwiftUI.Font.Weight = .semibold) -> SwiftUI.Font {
            .system(size: size, weight: weight, design: .rounded).monospacedDigit()
        }
    }
}
