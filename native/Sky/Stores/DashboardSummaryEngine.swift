import Foundation

/// Aggregated dashboard facts. This type intentionally contains no titles, names,
/// monetary values, event details, task details, book details, or activity details.
struct DashboardSignals: Equatable, Sendable {
    var generatedAt: Date
    var upcomingEventCount: Int?
    var remainingTaskCount: Int?
    var completedTaskCount: Int
    var commitsToday: Int?
    var portfolioDayChangePercent: Double?
    var isMusicPlaying: Bool?
    var activeReadingProgressPercent: Int?
    var recentExerciseMinutes: Int?
    var daysSinceExercise: Int?

    init(
        generatedAt: Date = Date(),
        upcomingEventCount: Int? = nil,
        remainingTaskCount: Int? = nil,
        completedTaskCount: Int = 0,
        commitsToday: Int? = nil,
        portfolioDayChangePercent: Double? = nil,
        isMusicPlaying: Bool? = nil,
        activeReadingProgressPercent: Int? = nil,
        recentExerciseMinutes: Int? = nil,
        daysSinceExercise: Int? = nil
    ) {
        self.generatedAt = generatedAt
        self.upcomingEventCount = upcomingEventCount
        self.remainingTaskCount = remainingTaskCount
        self.completedTaskCount = completedTaskCount
        self.commitsToday = commitsToday
        self.portfolioDayChangePercent = portfolioDayChangePercent
        self.isMusicPlaying = isMusicPlaying
        self.activeReadingProgressPercent = activeReadingProgressPercent
        self.recentExerciseMinutes = recentExerciseMinutes
        self.daysSinceExercise = daysSinceExercise
    }
}

struct DashboardSummary: Equatable, Sendable {
    enum Source: Equatable, Sendable {
        case local
        case externalAI
    }

    let text: String
    let source: Source
}

enum DashboardSummaryEngine {
    static func localSummary(for signals: DashboardSignals, calendar: Calendar = .current) -> DashboardSummary {
        let hour = calendar.component(.hour, from: signals.generatedAt)
        let schedule = schedulePhrase(
            events: signals.upcomingEventCount,
            tasks: signals.remainingTaskCount
        )

        let text: String
        if hour >= 22 || hour < 6 {
            if let schedule, schedule != "a clear schedule" {
                text = "Quiet mode: \(schedule) can wait until tomorrow."
            } else {
                text = "Quiet mode is on, with nothing urgent asking for attention."
            }
        } else if signals.completedTaskCount >= 5 || (signals.commitsToday ?? 0) >= 4 {
            text = momentumSummary(for: signals, schedule: schedule)
        } else if let change = signals.portfolioDayChangePercent, abs(change) >= 1 {
            let direction = change > 0 ? "up" : "down"
            text = schedule.map { "Markets are \(direction) today, with \($0)." }
                ?? "Markets are \(direction) today; the rest of the dashboard looks steady."
        } else if let days = signals.daysSinceExercise, days >= 2 {
            text = schedule.map { "\($0), and it has been a few days since your last workout." }
                ?? "It has been a few days since your last workout, so a little movement may help."
        } else if let schedule {
            text = "You have \(schedule), and the rest of the day looks steady."
        } else if signals.isMusicPlaying == true {
            text = "Music is playing, and the dashboard is otherwise quiet."
        } else if signals.activeReadingProgressPercent != nil {
            text = "Your current read is in progress, with no other strong signal competing for attention."
        } else {
            text = "The dashboard is quiet, with no strong signal needing attention."
        }

        return DashboardSummary(text: text, source: .local)
    }

    private static func momentumSummary(for signals: DashboardSignals, schedule: String?) -> String {
        let completed = signals.completedTaskCount
        let commits = signals.commitsToday ?? 0
        let momentum: String
        if completed >= 5, commits >= 4 {
            momentum = "Strong momentum from completed tasks and coding"
        } else if completed >= 5 {
            momentum = "You have already cleared several tasks"
        } else {
            momentum = "Coding momentum is strong today"
        }

        return schedule.map { "\(momentum), with \($0)." }
            ?? "\(momentum), and the rest of the dashboard looks clear."
    }

    private static func schedulePhrase(events: Int?, tasks: Int?) -> String? {
        let eventCount = max(0, events ?? 0)
        let taskCount = max(0, tasks ?? 0)
        let eventsAvailable = events != nil
        let tasksAvailable = tasks != nil

        switch (eventsAvailable && eventCount > 0, tasksAvailable && taskCount > 0) {
        case (true, true):
            return "\(count(eventCount, singular: "event")) and \(count(taskCount, singular: "task")) ahead"
        case (true, false):
            return "\(count(eventCount, singular: "event")) ahead"
        case (false, true):
            return "\(count(taskCount, singular: "task")) remaining"
        case (false, false):
            if eventsAvailable || tasksAvailable { return "a clear schedule" }
            return nil
        }
    }

    private static func count(_ value: Int, singular: String) -> String {
        "\(value) \(value == 1 ? singular : "\(singular)s")"
    }
}

// MARK: - Optional privacy-safe AI enhancement

private struct DashboardAISummaryRequest: Encodable {
    let signals: DashboardAIProjection
}

private struct DashboardAIProjection: Encodable {
    enum Period: String, Encodable { case morning, afternoon, evening, night }
    enum Load: String, Encodable { case unknown, clear, light, busy }
    enum Momentum: String, Encodable { case unknown, quiet, active, strong }
    enum Trend: String, Encodable { case unknown, down, flat, up }
    enum Recency: String, Encodable { case unknown, recent, stale }

    let period: Period
    let calendarLoad: Load
    let taskLoad: Load
    let codingMomentum: Momentum
    let portfolioTrend: Trend
    let musicPlaying: Bool?
    let exerciseRecency: Recency
    let readingActive: Bool?

    init(signals: DashboardSignals, calendar: Calendar = .current) {
        let hour = calendar.component(.hour, from: signals.generatedAt)
        switch hour {
        case 6..<12: period = .morning
        case 12..<18: period = .afternoon
        case 18..<22: period = .evening
        default: period = .night
        }

        calendarLoad = Self.load(signals.upcomingEventCount, busyThreshold: 4)
        taskLoad = Self.load(signals.remainingTaskCount, busyThreshold: 6)
        codingMomentum = Self.momentum(signals.commitsToday)
        portfolioTrend = Self.trend(signals.portfolioDayChangePercent)
        musicPlaying = signals.isMusicPlaying
        exerciseRecency = Self.recency(signals.daysSinceExercise)
        readingActive = signals.activeReadingProgressPercent.map { $0 > 0 && $0 < 100 }
    }

    private static func load(_ count: Int?, busyThreshold: Int) -> Load {
        guard let count else { return .unknown }
        if count <= 0 { return .clear }
        if count >= busyThreshold { return .busy }
        return .light
    }

    private static func momentum(_ commits: Int?) -> Momentum {
        guard let commits else { return .unknown }
        if commits <= 0 { return .quiet }
        if commits >= 4 { return .strong }
        return .active
    }

    private static func trend(_ percent: Double?) -> Trend {
        guard let percent, percent.isFinite else { return .unknown }
        if percent > 0.25 { return .up }
        if percent < -0.25 { return .down }
        return .flat
    }

    private static func recency(_ days: Int?) -> Recency {
        guard let days else { return .unknown }
        return days >= 2 ? .stale : .recent
    }
}

enum DashboardSummaryService {
    static func localSummary(for signals: DashboardSignals) -> DashboardSummary {
        DashboardSummaryEngine.localSummary(for: signals)
    }

    /// Returns nil unless the user explicitly opted in and Groq is configured.
    /// The request body is a coarse projection, never the local signal value itself.
    @MainActor
    static func optionalAISummary(
        for signals: DashboardSignals,
        configuration: IntegrationConfigStore
    ) async -> DashboardSummary? {
        guard configuration.isAIPrivacyOptedIn, configuration.isConfigured("groq") else { return nil }

        let request = DashboardAISummaryRequest(signals: DashboardAIProjection(signals: signals))
        guard let response: GreetingResponse = try? await APIClient.shared.post("/api/ai/greeting", body: request),
              let message = sanitized(response.message) else {
            return nil
        }
        return DashboardSummary(text: message, source: .externalAI)
    }

    private static func sanitized(_ message: String) -> String? {
        let singleLine = message
            .split(whereSeparator: \Character.isNewline)
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !singleLine.isEmpty else { return nil }
        return String(singleLine.prefix(180))
    }
}
