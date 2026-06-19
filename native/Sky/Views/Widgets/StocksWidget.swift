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
            VStack(spacing: 10) {
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

    var body: some View {
        HStack(spacing: 10) {
            Text(quote.symbol)
                .font(.subheadline.weight(.semibold))
            Spacer(minLength: 8)
            Text(quote.price, format: .number.precision(.fractionLength(2)))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
                .monospacedDigit()
            HStack(spacing: 2) {
                Image(systemName: isUp ? "arrow.up.right" : "arrow.down.right")
                    .font(.caption2.weight(.bold))
                Text(abs(quote.changePercent), format: .number.precision(.fractionLength(2)))
                    + Text("%")
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(changeColor)
            .monospacedDigit()
            .frame(width: 72, alignment: .trailing)
        }
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
