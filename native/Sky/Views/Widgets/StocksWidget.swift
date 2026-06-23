import SwiftUI
import Charts

struct StocksWidget: View {
    @Environment(DashboardStore.self) private var store
    @Environment(\.widgetSize) private var size
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
            tint: Tokens.accent,
            state: store.stocks,
            isEmpty: \.isEmpty,
            emptyText: "No tickers — tap the pencil to add some",
            reload: { await store.load(.stocks, force: true, stockSymbols: symbols) },
            accessory: {
                if size != .small {
                    Button {
                        isEditing = true
                    } label: {
                        Image(systemName: "pencil")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.borderless)
                }
            }
        ) { quotes in
            stocksContent(quotes: quotes)
        }
        .task(id: query) { await store.load(.stocks, force: true, stockSymbols: symbols) }
        .sheet(isPresented: $isEditing) {
            TickerEditor(tickersCSV: $tickersCSV)
        }
    }

    @ViewBuilder
    private func stocksContent(quotes: [StockQuote]) -> some View {
        switch size {
        case .small:
            if let first = quotes.first {
                StockHero(quote: first)
            }
        case .medium:
            VStack(spacing: Tokens.contentSpacing) {
                ForEach(quotes) { StockRow(quote: $0) }
            }
        case .large:
            VStack(spacing: Tokens.contentSpacing) {
                ForEach(quotes) { StockRow(quote: $0, showSparkline: true) }
            }
        }
    }
}

/// Small: single ticker hero with symbol, price, and change%.
private struct StockHero: View {
    let quote: StockQuote

    private var isUp: Bool { quote.changePercent >= 0 }
    private var changeColor: Color { isUp ? Tokens.positive : Tokens.negative }
    private var arrowSymbol: String { isUp ? "arrow.up.right" : "arrow.down.right" }

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.snug) {
            Text(quote.symbol)
                .font(Tokens.Font.bodyRowStrong)
                .foregroundStyle(.primary)

            Text(quote.price, format: .number.precision(.fractionLength(2)))
                .font(.system(.title, design: .rounded).weight(.semibold))
                .monospacedDigit()
                .contentTransition(.numericText())

            Label(changeText, systemImage: arrowSymbol)
                .font(Tokens.Font.bodyRow)
                .monospacedDigit()
                .foregroundStyle(changeColor)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(quote.symbol)
        .accessibilityValue(
            "Price \(quote.price.formatted(.number.precision(.fractionLength(2)))), "
                + "\(changeText)"
        )
    }

    private var changeText: String {
        (quote.changePercent / 100).formatted(
            .percent.sign(strategy: .always()).precision(.fractionLength(2))
        )
    }
}

private struct StockRow: View {
    let quote: StockQuote
    var showSparkline: Bool = false

    private var isUp: Bool { quote.changePercent >= 0 }
    private var changeColor: Color { isUp ? Tokens.positive : Tokens.negative }
    private var arrowSymbol: String { isUp ? "arrow.up.right" : "arrow.down.right" }

    var body: some View {
        Link(destination: URL(string: "https://finance.yahoo.com/quote/\(quote.symbol)") ?? URL(string: "https://finance.yahoo.com")!) {
            HStack(spacing: Tokens.rowSpacing) {
                VStack(alignment: .leading, spacing: Tokens.microSpacing) {
                    Text(quote.symbol)
                        .font(Tokens.Font.bodyRowStrong)
                        .foregroundStyle(.primary)
                    Text(
                        quote.change,
                        format: .number.sign(strategy: .always()).precision(.fractionLength(2))
                    )
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }

                if showSparkline, let spark = quote.spark, spark.count > 1 {
                    Sparkline(values: spark, color: changeColor)
                        .frame(maxWidth: Tokens.Size.artwork)
                        .frame(height: Tokens.Size.stockSparklineHeight)
                }

                Spacer(minLength: Tokens.snug)

                VStack(alignment: .trailing, spacing: Tokens.extraTight) {
                    Text(quote.price, format: .number.precision(.fractionLength(2)))
                        .font(Tokens.Font.bodyRow)
                        .foregroundStyle(.primary)
                        .monospacedDigit()
                        .contentTransition(.numericText())

                    Label(changeText, systemImage: arrowSymbol)
                        .font(.caption2.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(changeColor)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(quote.symbol)
        .accessibilityValue(
            "Price \(quote.price.formatted(.number.precision(.fractionLength(2)))), "
                + "change \(quote.change.formatted(.number.precision(.fractionLength(2)))) "
                + "or \((quote.changePercent / 100).formatted(.percent.precision(.fractionLength(2))))"
        )
    }

    private var changeText: String {
        (quote.changePercent / 100).formatted(
            .percent.sign(strategy: .always()).precision(.fractionLength(2))
        )
    }
}

// Compact intraday sparkline (Swift Charts), gradient area under a smooth line.
// Apple HIG: minimal chrome, let the data shape speak. Generous vertical padding
// prevents the line from touching edges.
private struct Sparkline: View {
    let values: [Double]
    let color: Color

    var body: some View {
        let points = Array(values.enumerated())
        let lo = values.min() ?? 0
        let hi = values.max() ?? 1
        let range = hi - lo
        let padding = max(range * 0.12, 0.001)

        Chart(points, id: \.offset) { index, value in
            AreaMark(
                x: .value("t", index),
                yStart: .value("lo", lo - padding),
                yEnd: .value("price", value)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(
                .linearGradient(
                    colors: [color.opacity(0.2), color.opacity(0.0)],
                    startPoint: .top, endPoint: .bottom
                )
            )

            LineMark(x: .value("t", index), y: .value("price", value))
                .interpolationMethod(.catmullRom)
                .foregroundStyle(color)
                .lineStyle(StrokeStyle(lineWidth: 1.5, lineCap: .round))
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartYScale(domain: (lo - padding)...(hi + padding))
        .chartLegend(.hidden)
    }
}

private struct TickerEditor: View {
    @Binding var tickersCSV: String
    @Environment(\.dismiss) private var dismiss
    @State private var draft: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.gap) {
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
        .padding(Tokens.editorPadding)
        .frame(minWidth: Tokens.Size.editorMinWidth)
        .onAppear { draft = tickersCSV }
    }
}
