import SwiftUI

struct QuoteWidget: View {
    @State private var quote: ZenQuote?
    @State private var errorMessage: String?

    var body: some View {
        WidgetShell(title: "Daily Quote", symbol: "quote.bubble", tint: Tokens.accent) {
            if let errorMessage {
                WidgetError(message: errorMessage) {
                    Task { await fetchQuote() }
                }
            } else if let quote {
                QuoteContent(text: quote.q, author: quote.a)
            } else {
                WidgetLoading()
            }
        }
        .task { await fetchQuote() }
    }

    private func fetchQuote() async {
        errorMessage = nil
        guard let url = URL(string: "https://zenquotes.io/api/today") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let quotes = try JSONDecoder().decode([ZenQuote].self, from: data)
            guard let first = quotes.first else {
                errorMessage = "No quote available today"
                return
            }
            quote = first
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct QuoteContent: View {
    let text: String
    let author: String

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.contentSpacing) {
            HStack(alignment: .top, spacing: Tokens.snug) {
                Image(systemName: "quote.opening")
                    .font(.title3)
                    .foregroundStyle(Tokens.accent.opacity(0.4))
                    .accessibilityHidden(true)

                Text(text)
                    .font(Tokens.Font.bodyRow)
                    .italic()
                    .foregroundStyle(.primary)
                    .lineSpacing(Tokens.badgePadding)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Text("— \(author)")
                .font(.caption.weight(.medium))
                .foregroundStyle(.tertiary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - API Model

private struct ZenQuote: Codable, Sendable {
    let q: String
    let a: String
}
