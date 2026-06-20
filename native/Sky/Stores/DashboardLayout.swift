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
        DashboardSectionSpec(
            title: "Today",
            kinds: [.calendar, .tasks, .spotify],
            maxColumns: 2,
            minimumWidth: 310,
            maximumWidth: 420
        ),
        DashboardSectionSpec(
            title: "Portfolio",
            kinds: [.ibkr, .fair],
            maxColumns: 2,
            minimumWidth: 310,
            maximumWidth: 900
        ),
        DashboardSectionSpec(
            title: "At a glance",
            kinds: [.quote, .weather, .countdown],
            maxColumns: 3,
            minimumWidth: 250,
            maximumWidth: 420
        ),
        DashboardSectionSpec(
            title: "More",
            kinds: [.stocks, .github, .reading, .strava],
            maxColumns: 4,
            minimumWidth: 240,
            maximumWidth: 420
        ),
    ]

    static var defaultOrder: [WidgetKind] {
        all.flatMap(\.kinds)
    }
}
