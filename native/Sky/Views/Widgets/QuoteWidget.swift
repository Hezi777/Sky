import SwiftUI

struct QuoteWidget: View {
    @State private var quote: ZenQuote?
    @State private var errorMessage: String?

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                CardHeader(title: "Daily Quote", symbol: "quote.bubble", tint: Theme.accent)

                if let errorMessage {
                    WidgetError(message: errorMessage) {
                        Task { await fetchQuote() }
                    }
                } else if let quote {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "quote.opening")
                                .font(.title3)
                                .foregroundStyle(Theme.accent.opacity(0.4))

                            Text(quote.q)
                                .font(.subheadline.weight(.medium))
                                .italic()
                                .foregroundStyle(.primary)
                                .lineSpacing(3)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Text("— \(quote.a)")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.tertiary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                } else {
                    WidgetLoading()
                }
            }
        }
        .task { await fetchQuote() }
    }

    private func fetchQuote() async {
        guard let url = URL(string: "https://zenquotes.io/api/today") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let quotes = try JSONDecoder().decode([ZenQuote].self, from: data)
            quote = quotes.first
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - API Model

private struct ZenQuote: Codable, Sendable {
    let q: String
    let a: String
}
