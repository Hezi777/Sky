import Foundation

// Codable models for the new widget endpoints (stocks, reading).
// All Sendable so they can cross the APIClient actor boundary, matching
// APIModels.swift conventions (camelCase keys, no CodingKeys needed).

// MARK: - Stocks (/api/stocks)

struct StockQuote: Codable, Hashable, Identifiable, Sendable {
    let symbol: String
    let price: Double
    let changePercent: Double
    let change: Double
    /// Recent close prices (oldest→newest) for a sparkline. Present only when the
    /// backend has a TWELVEDATA_API_KEY; nil otherwise.
    let spark: [Double]?
    var id: String { symbol }
}

// MARK: - Reading (/api/notion/reading)

struct ReadingBook: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let title: String
    let author: String?
    let currentPage: Int?
    let totalPages: Int?
    let progress: Int
    let cover: String?
    let url: String
}
