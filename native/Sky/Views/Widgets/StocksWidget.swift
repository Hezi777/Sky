import SwiftUI

struct StocksWidget: View {
    @AppStorage("stocks.tickers") private var tickersCSV: String = "AAPL,MSFT,NVDA"
    @State private var isEditing = false

    private var symbols: [String] {
        tickersCSV
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces).uppercased() }
            .filter { !$0.isEmpty }
    }

    var body: some View {
        let query = symbols.joined(separator: ",")
        AsyncCard(
            title: "Stocks",
            symbol: "chart.line.uptrend.xyaxis",
            tint: Theme.accent,
            load: {
                try await APIClient.shared.get(
                    "/api/stocks", query: ["symbols": query]
                ) as [StockQuote]
            },
            isEmpty: \.isEmpty,
            emptyText: "No tickers — tap the pencil to add some"
        ) { quotes in
            VStack(spacing: 8) {
                ForEach(quotes) { StockRow(quote: $0) }
            }
        }
        // Force AsyncCard to reload whenever the ticker list changes.
        .id(query)
        .overlay(alignment: .topTrailing) {
            Button {
                isEditing = true
            } label: {
                Image(systemName: "pencil")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.borderless)
            .padding(Theme.cardPadding)
        }
        .sheet(isPresented: $isEditing) {
            TickerEditor(tickersCSV: $tickersCSV)
        }
    }
}

private struct StockRow: View {
    let quote: StockQuote

    private var isUp: Bool { quote.changePercent >= 0 }
    private var changeColor: Color { isUp ? .green : .red }
    private var arrowSymbol: String { isUp ? "arrow.up.right" : "arrow.down.right" }

    var body: some View {
        Link(destination: URL(string: "https://finance.yahoo.com/quote/\(quote.symbol)") ?? URL(string: "https://finance.yahoo.com")!) {
            HStack(spacing: 10) {
                Text(quote.symbol)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Spacer(minLength: 8)

                Text(quote.price, format: .number.precision(.fractionLength(2)))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .contentTransition(.numericText())

                HStack(spacing: 3) {
                    Image(systemName: arrowSymbol)
                        .font(.caption2.weight(.bold))

                    Text(changeText)
                        .font(.caption.weight(.semibold))
                        .monospacedDigit()
                }
                .foregroundStyle(changeColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(changeColor.opacity(0.12), in: Capsule())
            }
        }
        .buttonStyle(.plain)
    }

    private var changeText: String {
        let sign = isUp ? "+" : ""
        let val = String(format: "%.2f", quote.change)
        let pct = String(format: "%.2f", abs(quote.changePercent))
        return "\(sign)\(val) (\(pct)%)"
    }
}

private struct TickerEditor: View {
    @Binding var tickersCSV: String
    @Environment(\.dismiss) private var dismiss
    @State private var draft: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Edit tickers")
                .font(.headline)
            Text("Comma-separated symbols, e.g. AAPL, MSFT, NVDA")
                .font(.footnote)
                .foregroundStyle(.secondary)
            TextField("AAPL, MSFT, NVDA", text: $draft)
                .textFieldStyle(.roundedBorder)
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Save") {
                    tickersCSV = draft
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(minWidth: 320)
        .onAppear { draft = tickersCSV }
    }
}
