import Foundation
import Observation

enum DashboardLoadState<Value: Sendable>: Sendable {
    case idle
    case loading
    case loaded(Value)
    case failed(String)
}

extension DashboardLoadState: Equatable where Value: Equatable {}

struct DashboardSnapshot: Equatable, Sendable {
    var signals = DashboardSignals()
}

/// Shared live data for backend-backed widgets. Local-only widgets keep their
/// own state because they do not depend on the bundled service.
@MainActor
@Observable
final class DashboardStore {
    private(set) var snapshot = DashboardSnapshot()
    private(set) var calendar: DashboardLoadState<[CalendarEvent]> = .idle
    private(set) var tasks: DashboardLoadState<[TickTickTask]> = .idle
    private(set) var github: DashboardLoadState<GithubResponse> = .idle
    private(set) var spotify: DashboardLoadState<SpotifyResponse> = .idle
    private(set) var ibkr: DashboardLoadState<IbkrResponse> = .idle
    private(set) var fair: DashboardLoadState<FairPrice> = .idle
    private(set) var reading: DashboardLoadState<[ReadingBook]> = .idle
    private(set) var stocks: DashboardLoadState<[StockQuote]> = .idle
    private(set) var strava: DashboardLoadState<[StravaActivity]> = .idle
    private var completedTaskCount = 0
    private var loadingKinds: Set<WidgetKind> = []

    var signals: DashboardSignals { snapshot.signals }

    func loadVisible(_ widgets: [WidgetKind], configuredIntegrations: Set<String>) async {
        for kind in widgets where shouldLoad(kind, configuredIntegrations: configuredIntegrations) {
            await load(kind)
        }
    }

    func refreshVisible(_ widgets: [WidgetKind], configuredIntegrations: Set<String>) async {
        for kind in widgets where shouldLoad(kind, configuredIntegrations: configuredIntegrations) {
            await load(kind, force: true)
        }
    }

    func load(
        _ kind: WidgetKind,
        force: Bool = false,
        stockSymbols: [String]? = nil,
        fairFund: String? = nil
    ) async {
        guard !loadingKinds.contains(kind), force || needsLoad(kind) else { return }
        loadingKinds.insert(kind)
        defer { loadingKinds.remove(kind) }
        setLoading(kind)
        rebuildSnapshot()

        do {
            switch kind {
            case .calendar:
                calendar = .loaded(try await APIClient.shared.get("/api/calendar"))
            case .tasks:
                tasks = .loaded(try await APIClient.shared.get("/api/ticktick"))
            case .github:
                github = .loaded(try await APIClient.shared.get("/api/github"))
            case .spotify:
                spotify = .loaded(try await APIClient.shared.get("/api/spotify"))
            case .ibkr:
                ibkr = .loaded(try await APIClient.shared.get("/api/ibkr"))
            case .fair:
                let fund = fairFund ?? UserDefaults.standard.string(forKey: "sky.fair.fund") ?? "5140785"
                fair = .loaded(try await APIClient.shared.get("/api/fair", query: ["fund": fund]))
            case .reading:
                reading = .loaded(try await APIClient.shared.get("/api/notion/reading"))
            case .stocks:
                let symbols = stockSymbols ?? storedStockSymbols
                stocks = .loaded(try await fetchStocks(symbols: symbols))
            case .strava:
                strava = .loaded(try await fetchStrava())
            case .quote, .weather, .countdown:
                break
            }
            rebuildSnapshot()
        } catch {
            setFailure(error, for: kind)
            rebuildSnapshot()
        }
    }

    func completeTask(_ task: TickTickTask) async -> Bool {
        do {
            let _: EmptyMutationResponse = try await APIClient.shared.post(
                "/api/ticktick/complete",
                body: ["id": task.id]
            )
            completedTaskCount += 1
            await load(.tasks, force: true)
            return true
        } catch {
            setFailure(error, for: .tasks)
            rebuildSnapshot()
            return false
        }
    }

    private var storedStockSymbols: [String] {
        let value = UserDefaults.standard.string(forKey: "stocks.tickers") ?? "AAPL,MSFT,NVDA"
        return value.split(separator: ",").map {
            $0.trimmingCharacters(in: .whitespaces).uppercased()
        }.filter { !$0.isEmpty }
    }

    private func shouldLoad(_ kind: WidgetKind, configuredIntegrations: Set<String>) -> Bool {
        guard !kind.isLocalOnly else { return false }
        guard let integrationID = kind.integrationID else { return true }
        return configuredIntegrations.contains(integrationID)
    }

    private func needsLoad(_ kind: WidgetKind) -> Bool {
        switch kind {
        case .calendar: return calendar.needsLoad
        case .tasks: return tasks.needsLoad
        case .github: return github.needsLoad
        case .spotify: return spotify.needsLoad
        case .ibkr: return ibkr.needsLoad
        case .fair: return fair.needsLoad
        case .reading: return reading.needsLoad
        case .stocks: return stocks.needsLoad
        case .strava: return strava.needsLoad
        case .quote, .weather, .countdown: return false
        }
    }

    private func setLoading(_ kind: WidgetKind) {
        switch kind {
        case .calendar: calendar = .loading
        case .tasks: tasks = .loading
        case .github: github = .loading
        case .spotify: spotify = .loading
        case .ibkr: ibkr = .loading
        case .fair: fair = .loading
        case .reading: reading = .loading
        case .stocks: stocks = .loading
        case .strava: strava = .loading
        case .quote, .weather, .countdown: break
        }
    }

    private func setFailure(_ error: Error, for kind: WidgetKind) {
        let message = (error as? APIError)?.errorDescription ?? error.localizedDescription
        switch kind {
        case .calendar: calendar = .failed(message)
        case .tasks: tasks = .failed(message)
        case .github: github = .failed(message)
        case .spotify: spotify = .failed(message)
        case .ibkr: ibkr = .failed(message)
        case .fair: fair = .failed(message)
        case .reading: reading = .failed(message)
        case .stocks: stocks = .failed(message)
        case .strava: strava = .failed(message)
        case .quote, .weather, .countdown: break
        }
    }

    private func fetchStocks(symbols: [String]) async throws -> [StockQuote] {
        let payload: StockPayload = try await APIClient.shared.get(
            "/api/stocks",
            query: ["symbols": symbols.joined(separator: ",")]
        )
        switch payload {
        case .quotes(let quotes): return quotes
        case .notConfigured(let message): throw APIError.server(message)
        }
    }

    private func fetchStrava() async throws -> [StravaActivity] {
        let payload: StravaPayload = try await APIClient.shared.get("/api/strava")
        switch payload {
        case .activities(let activities): return activities
        case .notConnected(let message): throw APIError.server(message)
        }
    }

    private func rebuildSnapshot(now: Date = Date()) {
        let events: Int? = if case .loaded(let value) = calendar { value.count } else { nil }
        let remainingTasks: Int? = if case .loaded(let value) = tasks { value.count } else { nil }

        let commitsToday: Int? = if case .loaded(let value) = github {
            value.contributions.first(where: { $0.date == Self.dayKey.string(from: now) })?.count ?? 0
        } else { nil }

        let portfolioChange: Double? = if case .loaded(let value) = ibkr,
                                          let dayPnl = value.summary.dayPnl {
            Self.percentChange(dayPnl: dayPnl, totalValue: value.summary.totalValue)
        } else { nil }

        let musicPlaying: Bool? = if case .loaded(let value) = spotify {
            value.nowPlaying?.isPlaying ?? false
        } else { nil }

        let readingProgress: Int? = if case .loaded(let value) = reading {
            value.max(by: { $0.progress < $1.progress })?.progress
        } else { nil }

        let exercise: (minutes: Int?, daysSince: Int?) = if case .loaded(let value) = strava {
            Self.exerciseSignals(activities: value, now: now)
        } else { (nil, nil) }

        snapshot = DashboardSnapshot(signals: DashboardSignals(
            generatedAt: now,
            upcomingEventCount: events,
            remainingTaskCount: remainingTasks,
            completedTaskCount: completedTaskCount,
            commitsToday: commitsToday,
            portfolioDayChangePercent: portfolioChange,
            isMusicPlaying: musicPlaying,
            activeReadingProgressPercent: readingProgress,
            recentExerciseMinutes: exercise.minutes,
            daysSinceExercise: exercise.daysSince
        ))
    }

    private static func percentChange(dayPnl: Double, totalValue: Double) -> Double? {
        let priorValue = totalValue - dayPnl
        guard priorValue > 0 else { return nil }
        return ((dayPnl / priorValue) * 1_000).rounded() / 10
    }

    private static func exerciseSignals(
        activities: [StravaActivity],
        now: Date
    ) -> (minutes: Int?, daysSince: Int?) {
        let dated = activities.compactMap { activity in
            ISO8601DateFormatter.parse(activity.startDate).map { ($0, activity.movingTime) }
        }
        guard let latest = dated.max(by: { $0.0 < $1.0 }) else { return (0, nil) }
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now
        let minutes = dated.filter { $0.0 >= cutoff }.reduce(0) { $0 + $1.1 } / 60
        let days = max(0, Calendar.current.dateComponents([.day], from: latest.0, to: now).day ?? 0)
        return (minutes, days)
    }

    private static let dayKey: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

private extension DashboardLoadState {
    var needsLoad: Bool {
        switch self {
        case .idle, .failed: true
        case .loading, .loaded: false
        }
    }
}

private struct EmptyMutationResponse: Decodable, Sendable {}

private enum StockPayload: Decodable, Sendable {
    case quotes([StockQuote])
    case notConfigured(String)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let quotes = try? container.decode([StockQuote].self) {
            self = .quotes(quotes)
        } else {
            self = .notConfigured(try container.decode(APIErrorBody.self).error)
        }
    }
}

private enum StravaPayload: Decodable, Sendable {
    case activities([StravaActivity])
    case notConnected(String)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let activities = try? container.decode([StravaActivity].self) {
            self = .activities(activities)
        } else {
            self = .notConnected(try container.decode(APIErrorBody.self).error)
        }
    }
}
