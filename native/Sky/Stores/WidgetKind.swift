import SwiftUI

// Every toggleable dashboard widget. The cloud/greeting hero is always shown and
// is not part of this list.

/// How much horizontal room a widget claims in the dashboard flow.
enum WidgetSpan: Equatable {
    /// Flows into the responsive grid alongside its neighbours.
    case regular
    /// Uses two adjacent columns when available for dense horizontal content.
    case wide
}

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

    /// Dashboard layout footprint. Dense horizontal widgets get two columns;
    /// compact widgets use one and fill the shortest available column.
    var span: WidgetSpan {
        switch self {
        case .github, .spotify: .wide
        default: .regular
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
