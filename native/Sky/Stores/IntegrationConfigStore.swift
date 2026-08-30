import Foundation
import Observation

struct IntegrationConfigImportResult: Equatable {
    let importedKeyNames: Set<String>
    let ignoredKeyNames: Set<String>
    let invalidLineNumbers: [Int]
}

struct IntegrationConfigStatus: Identifiable, Equatable {
    let id: String
    let name: String
    let keyNames: Set<String>
    let configuredKeyNames: Set<String>
    let isConfigured: Bool
}

@MainActor
@Observable
final class IntegrationConfigStore {
    static let allowedKeyNames: Set<String> = [
        "FINNHUB_API_KEY", "GITHUB_PAT", "GITHUB_USERNAME", "GOOGLE_CLIENT_ID",
        "GOOGLE_CLIENT_SECRET", "GOOGLE_REFRESH_TOKEN", "GROQ_API_KEY", "IBKR_ACCOUNT_ID",
        "IBKR_DATA_SOURCE", "IBKR_FLEX_CACHE_MS", "IBKR_FLEX_QUERY_ID", "IBKR_FLEX_TOKEN",
        "IBKR_GATEWAY_URL", "IBKR_KEEPALIVE_INTERVAL_MS", "NOTION_PROJECTS_DB_ID",
        "NOTION_READING_DATA_SOURCE_ID", "NOTION_RESOURCES_DB_ID", "NOTION_TOKEN",
        "SPOTIFY_CLIENT_ID", "SPOTIFY_CLIENT_SECRET",
        "SPOTIFY_REFRESH_TOKEN", "TICKTICK_ACCESS_TOKEN", "TICKTICK_MCP_TOKEN",
        "TICKTICK_PASSWORD", "TICKTICK_USERNAME", "TWELVEDATA_API_KEY",
    ]

    private static let onboardingCompleteKey = "sky.metadata.onboarding-complete"
    private static let aiPrivacyOptInKey = "sky.metadata.ai-privacy-opt-in"
    private static let definitions: [(id: String, name: String, keys: Set<String>)] = [
        ("googleCalendar", "Google Calendar", ["GOOGLE_CLIENT_ID", "GOOGLE_CLIENT_SECRET", "GOOGLE_REFRESH_TOKEN"]),
        ("tickTick", "TickTick", ["TICKTICK_MCP_TOKEN", "TICKTICK_USERNAME", "TICKTICK_PASSWORD", "TICKTICK_ACCESS_TOKEN"]),
        ("spotify", "Spotify", ["SPOTIFY_CLIENT_ID", "SPOTIFY_CLIENT_SECRET", "SPOTIFY_REFRESH_TOKEN"]),
        ("stocks", "Stocks", ["FINNHUB_API_KEY", "TWELVEDATA_API_KEY"]),
        ("github", "GitHub", ["GITHUB_PAT", "GITHUB_USERNAME"]),
        ("notionReading", "Notion Reading", ["NOTION_TOKEN", "NOTION_READING_DATA_SOURCE_ID"]),
        (
            "ibkr",
            "Interactive Brokers",
            [
                "IBKR_ACCOUNT_ID", "IBKR_DATA_SOURCE", "IBKR_FLEX_TOKEN", "IBKR_FLEX_QUERY_ID",
                "IBKR_GATEWAY_URL",
            ]
        ),
        ("groq", "Groq AI", ["GROQ_API_KEY"]),
    ]

    private let keychain: KeychainStore
    private(set) var configuredKeyNames: Set<String> = []
    private(set) var isOnboardingComplete = false
    private(set) var isAIPrivacyOptedIn = false
    private(set) var configurationRevision = 0

    init(keychain: KeychainStore = KeychainStore()) {
        self.keychain = keychain
        refreshStatus()
    }

    var integrationStatuses: [IntegrationConfigStatus] {
        Self.definitions.map { definition in
            let configured = definition.keys.intersection(configuredKeyNames)
            return IntegrationConfigStatus(
                id: definition.id,
                name: definition.name,
                keyNames: definition.keys,
                configuredKeyNames: configured,
                isConfigured: isIntegrationConfigured(definition.id)
            )
        }
    }

    func environmentValues() -> [String: String] {
        var values: [String: String] = [:]
        for key in configuredKeyNames {
            if let value = try? keychain.string(forKey: key), !value.isEmpty {
                values[key] = value
            }
        }
        return values
    }

    func isConfigured(_ integrationID: String) -> Bool {
        isIntegrationConfigured(integrationID)
    }

    func restartOnboarding() throws {
        try keychain.removeValue(forKey: Self.onboardingCompleteKey)
        isOnboardingComplete = false
    }

    func value(forKey key: String) throws -> String? {
        guard Self.allowedKeyNames.contains(key) else { return nil }
        return try keychain.string(forKey: key)
    }

    func setValue(_ value: String, forKey key: String) throws {
        guard Self.allowedKeyNames.contains(key) else { return }
        try keychain.setString(value, forKey: key)
        configuredKeyNames.insert(key)
        configurationRevision += 1
    }

    func setValues(_ values: [String: String]) throws {
        let allowedValues = values.filter { Self.allowedKeyNames.contains($0.key) }
        for (key, value) in allowedValues {
            if value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                try keychain.removeValue(forKey: key)
                configuredKeyNames.remove(key)
            } else {
                try keychain.setString(value, forKey: key)
                configuredKeyNames.insert(key)
            }
        }
        if !allowedValues.isEmpty { configurationRevision += 1 }
    }

    func removeValue(forKey key: String) throws {
        guard Self.allowedKeyNames.contains(key) else { return }
        try keychain.removeValue(forKey: key)
        configuredKeyNames.remove(key)
        configurationRevision += 1
    }

    @discardableResult
    func importEnvFile(at url: URL) throws -> IntegrationConfigImportResult {
        let hasScopedAccess = url.startAccessingSecurityScopedResource()
        defer {
            if hasScopedAccess { url.stopAccessingSecurityScopedResource() }
        }
        return try importEnvContents(String(contentsOf: url, encoding: .utf8))
    }

    @discardableResult
    func importEnvContents(_ contents: String) throws -> IntegrationConfigImportResult {
        let parsed = EnvFileParser(allowedKeyNames: Self.allowedKeyNames).parse(contents)
        var imported: Set<String> = []
        for (key, value) in parsed.values where !value.isEmpty {
            try keychain.setString(value, forKey: key)
            imported.insert(key)
        }
        configuredKeyNames.formUnion(imported)
        if !imported.isEmpty { configurationRevision += 1 }
        return IntegrationConfigImportResult(
            importedKeyNames: imported,
            ignoredKeyNames: parsed.ignoredKeyNames,
            invalidLineNumbers: parsed.invalidLineNumbers
        )
    }

    func setAIPrivacyOptIn(_ isOptedIn: Bool) throws {
        try keychain.setString(isOptedIn ? "true" : "false", forKey: Self.aiPrivacyOptInKey)
        isAIPrivacyOptedIn = isOptedIn
    }

    func markOnboardingComplete() throws {
        try keychain.setString("true", forKey: Self.onboardingCompleteKey)
        isOnboardingComplete = true
    }

    private func refreshStatus() {
        configuredKeyNames = Set(Self.allowedKeyNames.filter { key in
            (try? keychain.string(forKey: key)) != nil
        })
        isOnboardingComplete = (try? keychain.string(forKey: Self.onboardingCompleteKey)) == "true"
        isAIPrivacyOptedIn = (try? keychain.string(forKey: Self.aiPrivacyOptInKey)) == "true"
    }

    private func isIntegrationConfigured(_ id: String) -> Bool {
        func has(_ key: String) -> Bool { configuredKeyNames.contains(key) }
        func hasAll(_ keys: [String]) -> Bool { keys.allSatisfy(has) }

        switch id {
        case "googleCalendar":
            return hasAll(["GOOGLE_CLIENT_ID", "GOOGLE_CLIENT_SECRET", "GOOGLE_REFRESH_TOKEN"])
        case "tickTick":
            return has("TICKTICK_MCP_TOKEN")
                || hasAll(["TICKTICK_USERNAME", "TICKTICK_PASSWORD"])
                || has("TICKTICK_ACCESS_TOKEN")
        case "spotify":
            return hasAll(["SPOTIFY_CLIENT_ID", "SPOTIFY_CLIENT_SECRET", "SPOTIFY_REFRESH_TOKEN"])
        case "stocks":
            return has("FINNHUB_API_KEY")
        case "github":
            return has("GITHUB_PAT")
        case "notionReading":
            return hasAll(["NOTION_TOKEN", "NOTION_READING_DATA_SOURCE_ID"])
        case "ibkr":
            let source = (try? keychain.string(forKey: "IBKR_DATA_SOURCE")) ?? "auto"
            let flex = hasAll(["IBKR_FLEX_TOKEN", "IBKR_FLEX_QUERY_ID"])
            let gateway = has("IBKR_GATEWAY_URL")
            if source == "flex" { return flex }
            if source == "gateway" { return gateway }
            return flex || gateway
        case "groq":
            return has("GROQ_API_KEY")
        default:
            return false
        }
    }
}
