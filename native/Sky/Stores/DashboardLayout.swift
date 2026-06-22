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
        // Time & Agenda — most actionable, glanceable at start of day
        DashboardSectionSpec(
            title: "Time & Agenda",
            kinds: [.calendar, .tasks, .countdown],
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
        // Activity & Wellness — body and mind
        DashboardSectionSpec(
            title: "Activity",
            kinds: [.strava, .github, .weather],
            maxColumns: 3,
            minimumWidth: 250,
            maximumWidth: 420
        ),
        // Ambient — mood, inspiration, leisure
        DashboardSectionSpec(
            title: "Ambient",
            kinds: [.spotify, .quote, .reading],
            maxColumns: 3,
            minimumWidth: 250,
            maximumWidth: 420
        ),
    ]

    static var defaultOrder: [WidgetKind] {
        all.flatMap(\.kinds)
    }
}
