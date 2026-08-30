import Foundation

// MARK: - Persisted config

struct FairConfig: Codable, Sendable {
    var fundNumber: String
    var fundName: String
    var manualPrice: Double?
    var contributions: [FairContribution]
}

// MARK: - Store

/// Owns the user's Fair fund DCA config and persists it as JSON to Application
/// Support. Every mutation saves immediately — no data loss on crash.
@Observable @MainActor
final class FairStore {

    private(set) var config: FairConfig

    // MARK: Persistence

    private static let fileName = "fair.json"

    private static var fileURL: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Sky", isDirectory: true)
        return dir.appendingPathComponent(fileName)
    }

    private static let defaultConfig = FairConfig(
        fundNumber: "5140785",
        fundName: "Meitav",
        manualPrice: nil,
        contributions: []
    )

    init() {
        // Demo mode never reads or writes the real fund file — it renders
        // fabricated contributions from `DemoFixtures` and every mutation
        // no-ops (see `save()`).
        guard !DemoMode.isEnabled else {
            config = DemoFixtures.fair
            return
        }
        let url = Self.fileURL
        if let data = try? Data(contentsOf: url) {
            if let decoded = try? JSONDecoder().decode(FairConfig.self, from: data) {
                config = decoded
            } else {
                // File exists but is unreadable. Preserve the raw bytes before the
                // first save() overwrites them, so contributions can be recovered.
                try? data.write(to: url.appendingPathExtension("bak"), options: .atomic)
                config = Self.defaultConfig
            }
        } else {
            config = Self.defaultConfig
        }
    }

    private func save() {
        guard !DemoMode.isEnabled else { return }
        let url = Self.fileURL
        let dir = url.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        if let data = try? JSONEncoder().encode(config) {
            try? data.write(to: url, options: .atomic)
        }
    }

    // MARK: Mutations

    func add(contribution: FairContribution) {
        config.contributions.append(contribution)
        save()
    }

    func remove(id: String) {
        config.contributions.removeAll { $0.id == id }
        save()
    }

    func updateConfig(fundNumber: String? = nil, fundName: String? = nil, manualPrice: Double?? = nil) {
        if let fundNumber { config.fundNumber = fundNumber }
        if let fundName { config.fundName = fundName }
        if let manualPrice { config.manualPrice = manualPrice }
        save()
    }

    // MARK: Computed totals

    var invested: Double {
        config.contributions.reduce(0) { $0 + $1.amount }
    }

    var units: Double {
        config.contributions.reduce(0) { $0 + $1.units }
    }

    func value(at effectivePrice: Double) -> Double {
        units * effectivePrice
    }

    func gain(at effectivePrice: Double) -> Double {
        value(at: effectivePrice) - invested
    }

    func gainPercent(at effectivePrice: Double) -> Double? {
        guard invested > 0 else { return nil }
        return (gain(at: effectivePrice) / invested) * 100
    }

    // MARK: Import / Export

    func exportJSON() -> Data {
        // Always produce valid, importable JSON — never an empty file the user
        // could mistake for a backup.
        if let data = try? JSONEncoder().encode(config) { return data }
        return (try? JSONEncoder().encode(Self.defaultConfig)) ?? Data()
    }

    func importJSON(_ data: Data) throws {
        let decoded = try JSONDecoder().decode(FairConfig.self, from: data)
        config = decoded
        save()
    }
}
