import Foundation

// Codable models mirroring the backend `lib/types.ts`. The API returns camelCase
// JSON, so property names match the keys directly (no CodingKeys needed).

// MARK: - Errors

struct APIErrorBody: Codable, Sendable {
    let error: String
}

// MARK: - Spotify

struct SpotifyTrack: Codable, Hashable, Identifiable, Sendable {
    let title: String
    let artist: String
    let albumArt: String?
    let url: String
    var id: String { url }
}

struct SpotifyNowPlaying: Codable, Hashable, Sendable {
    let title: String
    let artist: String
    let albumArt: String?
    let url: String
    let isPlaying: Bool
    let progressMs: Int
    let durationMs: Int
}

struct SpotifyResponse: Codable, Equatable, Sendable {
    let nowPlaying: SpotifyNowPlaying?
    let recent: [SpotifyTrack]
}

// MARK: - GitHub

struct GithubRepo: Codable, Hashable, Identifiable, Sendable {
    let name: String
    let description: String?
    let language: String?
    let stars: Int
    let pushedAt: String
    let url: String
    var id: String { url }
}

struct GithubContributionDay: Codable, Hashable, Identifiable, Sendable {
    let date: String      // YYYY-MM-DD
    let count: Int
    let level: Int        // 0...4
    var id: String { date }
}

struct GithubResponse: Codable, Equatable, Sendable {
    let repos: [GithubRepo]
    let contributions: [GithubContributionDay]
    let totalContributions: Int
}

// MARK: - Notion

struct NotionProject: Codable, Hashable, Identifiable {
    let id: String
    let name: String
    let stage: String
    let type: String?
    let stack: String?
    let nextAction: String?
    let url: String
}

typealias NotionNextTask = NotionProject

// MARK: - Google Calendar

struct CalendarEvent: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let title: String
    let start: String     // ISO
    let end: String       // ISO
    let allDay: Bool
    let location: String?
    let colorId: String?
    let url: String?
}

// MARK: - TickTick

enum TickTickPriority: String, Codable, Hashable, Sendable {
    case none, low, medium, high
}

struct TickTickTask: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let projectId: String
    let title: String
    let priority: TickTickPriority
    let dueDate: String?
    let tags: [String]
    let subtaskCount: Int
}

// MARK: - IBKR

struct IbkrPosition: Codable, Hashable, Identifiable, Sendable {
    let ticker: String
    let shares: Double
    let avgCost: Double
    let currentPrice: Double
    let marketValue: Double
    let pnlPercent: Double
    var id: String { ticker }
}

struct IbkrSummary: Codable, Hashable, Sendable {
    let totalValue: Double
    let dayPnl: Double?
    let unrealizedPnl: Double
    let unrealizedPnlPercent: Double
}

struct IbkrResponse: Codable, Equatable, Sendable {
    enum Source: String, Codable, Sendable { case gateway, flex }
    let source: Source
    let asOf: String?
    let summary: IbkrSummary
    let positions: [IbkrPosition]
}

// MARK: - AI (Groq)

struct GreetingResponse: Codable {
    let message: String
}

struct GreetingRequest: Codable {
    var events: [String] = []
    var tasks: [String] = []
    var commits: Int?
    var portfolioChange: Double?
    var nowPlaying: String?
    var mood: String?
}

// MARK: - Fair (Israeli mutual fund DCA tracker)

struct FairPrice: Codable, Equatable, Sendable {
    let price: Double
    let asOf: String
    let currency: String
    let source: String
    let fundName: String?
}

struct FairContribution: Codable, Hashable, Identifiable {
    let id: String
    let date: String       // YYYY-MM-DD
    let amount: Double
    let units: Double
}
