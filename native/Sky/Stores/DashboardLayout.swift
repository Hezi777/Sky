import CoreGraphics

// Dashboard layout metadata. The view itself handles row composition;
// this type only provides the canonical widget order for DashboardConfig.

struct DashboardSectionSpec: Identifiable {
    let title: String
    let kinds: [WidgetKind]
    let maxColumns: Int
    let minimumWidth: CGFloat
    let maximumWidth: CGFloat

    var id: String { title }

    static let all: [DashboardSectionSpec] = [
        // Focus — immediate commitments and the context needed to act on them.
        DashboardSectionSpec(
            title: "Focus",
            kinds: [.calendar, .tasks, .weather, .countdown],
            maxColumns: 2,
            minimumWidth: 310,
            maximumWidth: 520
        ),
        // Finance — portfolio, fund, stocks grouped together
        DashboardSectionSpec(
            title: "Finance",
            kinds: [.ibkr, .fair, .stocks],
            maxColumns: 2,
            minimumWidth: 310,
            maximumWidth: 520
        ),
        // Growth — work, movement, and longer-term learning.
        DashboardSectionSpec(
            title: "Growth",
            kinds: [.github, .strava, .reading],
            maxColumns: 3,
            minimumWidth: 250,
            maximumWidth: 420
        ),
        // Ambient — optional media and inspiration after actionable signals.
        DashboardSectionSpec(
            title: "Ambient",
            kinds: [.spotify, .quote],
            maxColumns: 3,
            minimumWidth: 250,
            maximumWidth: 420
        ),
    ]

    static var defaultOrder: [WidgetKind] {
        all.flatMap(\.kinds)
    }

    /// Exact historical defaults eligible for automatic migration. A user order
    /// with even one deliberate move does not match and remains untouched.
    static let legacyDefaultOrders: [[WidgetKind]] = [
        [.calendar, .tasks, .countdown, .ibkr, .fair, .stocks,
         .strava, .github, .weather, .spotify, .quote, .reading],
        [.quote, .weather, .countdown, .calendar, .tasks, .spotify,
         .ibkr, .stocks, .fair, .github, .reading, .strava],
    ]
}
