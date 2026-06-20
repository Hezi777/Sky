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
        case .calendar: "calendar"
        case .tasks: "checklist"
        case .github: "chevron.left.forwardslash.chevron.right"
        case .spotify: "music.note"
        case .ibkr: "chart.pie.fill"
        case .fair: "chart.line.uptrend.xyaxis"
        case .reading: "book.fill"
        case .countdown: "airplane.departure"
        case .stocks: "chart.bar.fill"
        case .weather: "cloud.sun.fill"
        case .quote: "quote.bubble.fill"
        case .strava: "figure.run"
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
