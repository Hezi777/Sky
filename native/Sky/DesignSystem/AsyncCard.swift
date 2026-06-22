import SwiftUI

// The standard async widget container. Owns loading / error / empty states so
// each widget only declares: title, icon, how to fetch, and how to render.
//
// Usage:
//   AsyncCard(title: "Calendar", symbol: "calendar", tint: Theme.accent,
//             load: { try await APIClient.shared.get("/api/calendar") as [CalendarEvent] },
//             isEmpty: \.isEmpty, emptyText: "No upcoming events") { events in
//       ...render events...
//   }
//
// `Value` must be Sendable (it crosses the APIClient actor boundary) — all our
// Codable model structs already are.

struct AsyncCard<Value: Sendable, Accessory: View, Content: View>: View {
    let title: String
    let symbol: String
    var tint: Color = .secondary
    let load: () async throws -> Value
    var isEmpty: (Value) -> Bool = { _ in false }
    var emptyText: String = "Nothing here"
    @ViewBuilder let accessory: Accessory
    @ViewBuilder let content: (Value) -> Content

    @State private var value: Value?
    @State private var errorMessage: String?

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                CardHeader(title: title, symbol: symbol, tint: tint) {
                    accessory
                }

                if let errorMessage {
                    WidgetError(message: errorMessage) { Task { await reload() } }
                } else if let value {
                    if isEmpty(value) {
                        EmptyHint(text: emptyText)
                    } else {
                        content(value)
                    }
                } else {
                    WidgetLoading()
                }
            }
        }
        .task { await reload() }
    }

    private func reload() async {
        errorMessage = nil
        do {
            value = try await load()
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
    }
}

extension AsyncCard where Accessory == EmptyView {
    init(
        title: String,
        symbol: String,
        tint: Color = .secondary,
        load: @escaping () async throws -> Value,
        isEmpty: @escaping (Value) -> Bool = { _ in false },
        emptyText: String = "Nothing here",
        @ViewBuilder content: @escaping (Value) -> Content
    ) {
        self.init(
            title: title, symbol: symbol, tint: tint,
            load: load, isEmpty: isEmpty, emptyText: emptyText,
            accessory: { EmptyView() }, content: content
        )
    }
}

/// Small shared empty-state hint.
struct EmptyHint: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(.tertiary)
            .frame(maxWidth: .infinity, minHeight: 44)
    }
}

extension ISO8601DateFormatter {
    /// Parses ISO strings with or without fractional seconds. Reading is
    /// thread-safe for ISO8601DateFormatter, so the shared instance is fine.
    nonisolated(unsafe) static let flexible: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    /// Falls back to no-fractional-seconds parsing.
    static func parse(_ s: String) -> Date? {
        if let d = flexible.date(from: s) { return d }
        let plain = ISO8601DateFormatter()
        return plain.date(from: s)
    }
}
