import SwiftUI

// Every toggleable dashboard widget. The cloud/greeting hero is always shown and
// is not part of this list.

enum WidgetKind: String, CaseIterable, Codable, Identifiable {
    case quote, weather, countdown, calendar, tasks, spotify
    case ibkr, stocks, fair, github, reading, strava

    var id: String { rawValue }

    var title: String {
        switch self {
        case .calendar: "Calendar"
        case .tasks: "Today's Tasks"
        case .github: "GitHub"
        case .spotify: "Spotify"
        case .ibkr: "Portfolio"
        case .fair: "Fund Tracker"
        case .reading: "Reading"
        case .countdown: "Countdown"
        case .stocks: "Stocks"
        case .weather: "Weather"
        case .quote: "Daily Quote"
        case .strava: "Strava"
        }
    }

    var symbol: String {
        switch self {
        case .calendar: "calendar.day.timeline.left"
        case .tasks: "checklist"
        case .github: "curlybraces"
        case .spotify: "music.note"
        case .ibkr: "chart.pie"
        case .fair: "building.columns"
        case .reading: "book"
        case .countdown: "airplane.departure"
        case .stocks: "chart.line.uptrend.xyaxis"
        case .weather: "cloud.sun"
        case .quote: "quote.bubble"
        case .strava: "figure.run"
        }
    }

    /// Sizes this widget supports in the discrete grid.
    var supportedSizes: [WidgetSize] {
        switch self {
        case .quote, .countdown, .weather: [.small, .medium]
        case .calendar, .tasks, .fair, .stocks: [.small, .medium, .large]
        case .ibkr, .github: [.medium, .large]
        case .spotify: [.medium]
        case .reading, .strava: [.small, .medium]
        }
    }

    /// Default size for fresh installs; always within `supportedSizes`.
    var defaultSize: WidgetSize {
        switch self {
        case .ibkr, .github, .spotify, .calendar, .fair: .medium
        default: .small
        }
    }

    /// Widgets that don't need the bundled backend and remain usable when it is
    /// starting, unavailable, or intentionally disabled on iOS.
    var isLocalOnly: Bool {
        switch self {
        case .weather, .quote, .countdown: true
        default: false
        }
    }

    var integrationID: String? {
        switch self {
        case .calendar: "googleCalendar"
        case .tasks: "tickTick"
        case .spotify: "spotify"
        case .ibkr: "ibkr"
        case .stocks: "stocks"
        case .github: "github"
        case .reading: "notionReading"
        case .strava: "strava"
        case .quote, .weather, .countdown, .fair: nil
        }
    }

    /// Whether the widget is shown by default on first launch.
    var defaultVisible: Bool {
        switch self {
        case .calendar, .tasks, .github, .spotify, .ibkr, .fair: true
        case .weather, .countdown, .quote: true
        case .reading, .stocks, .strava: false
        }
    }
}
