import SwiftUI

/// Renders shared DashboardStore state with the same loading/error/empty shell
/// for every backend-backed widget.
struct AsyncCard<Value: Sendable, Accessory: View, Content: View>: View {
    let title: String
    let symbol: String
    var tint: Color = .secondary
    let state: DashboardLoadState<Value>
    var isEmpty: (Value) -> Bool = { _ in false }
    var emptyText: String = "Nothing here"
    let reload: () async -> Void
    @ViewBuilder let accessory: Accessory
    @ViewBuilder let content: (Value) -> Content

    var body: some View {
        WidgetShell(title: title, symbol: symbol, tint: tint) {
            accessory
        } content: {
            switch state {
            case .idle, .loading:
                WidgetLoading()
            case .failed(let message):
                WidgetError(message: message) { Task { await reload() } }
            case .loaded(let value):
                if isEmpty(value) { EmptyHint(text: emptyText) } else { content(value) }
            }
        }
    }
}

extension AsyncCard where Accessory == EmptyView {
    init(
        title: String,
        symbol: String,
        tint: Color = .secondary,
        state: DashboardLoadState<Value>,
        isEmpty: @escaping (Value) -> Bool = { _ in false },
        emptyText: String = "Nothing here",
        reload: @escaping () async -> Void,
        @ViewBuilder content: @escaping (Value) -> Content
    ) {
        self.init(
            title: title, symbol: symbol, tint: tint, state: state,
            isEmpty: isEmpty, emptyText: emptyText, reload: reload,
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
