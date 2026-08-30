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
            VStack(spacing: Tokens.zeroSpacing) {
                ForEach(Array(quotes.enumerated()), id: \.element.id) { index, quote in
                    stockRow(quote: quote, showSparkline: false, showsDivider: index < quotes.count - 1)
                }
            }
        case .large:
            VStack(spacing: Tokens.zeroSpacing) {
                ForEach(Array(quotes.enumerated()), id: \.element.id) { index, quote in
                    stockRow(quote: quote, showSparkline: true, showsDivider: index < quotes.count - 1)
                }
            }
        }
    }

    // MARK: - Stock row using WidgetRow

    @ViewBuilder
    private func stockRow(quote: StockQuote, showSparkline: Bool, showsDivider: Bool) -> some View {
        let isUp = quote.changePercent >= 0
        let changeColor = isUp ? Tokens.positive : Tokens.negative
        let changeText = (quote.changePercent / 100).formatted(
            .percent.sign(strategy: .always()).precision(.fractionLength(2))
        )

        Link(destination: URL(string: "https://finance.yahoo.com/quote/\(quote.symbol)") ?? URL(string: "https://finance.yahoo.com")!) {
            WidgetRow(
                title: quote.symbol,
                showsDivider: showsDivider,
                leading: {
                    if showSparkline, let spark = quote.spark, spark.count > 1 {
                        Sparkline(symbol: quote.symbol, values: spark, color: changeColor)
                            .frame(height: Tokens.Size.stockSparklineHeight)
                    } else {
                        EmptyView()
                    }
                },
                trailing: {
                    VStack(alignment: .trailing, spacing: Tokens.extraTight) {
                        Text(quote.price, format: .number.precision(.fractionLength(2)))
                            .font(Tokens.Font.rowTrailingValue)
                            .foregroundStyle(.primary)
                            .monospacedDigit()
                            .contentTransition(.numericText())

                        Text(changeText)
                            .font(Tokens.Font.rowTrailingValue)
                            .foregroundStyle(changeColor)
                            .monospacedDigit()
                    }
                }
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(quote.symbol)
        .accessibilityValue(
            "Price \(quote.price.formatted(.number.precision(.fractionLength(2)))), "
                + "\(changeText)"
        )
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
                .font(Tokens.Font.primaryValue(size: Tokens.Size.recentArtwork))
                .contentTransition(.numericText())

            Label(changeText, systemImage: arrowSymbol)
                .font(Tokens.Font.metricValue)
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

/// Compact intraday sparkline. Rides beside a row that already states the price
/// and the change, so it carries no axes and no readout of its own — its job is
/// the shape of the day, not a second copy of the number.
private struct Sparkline: View {
    let symbol: String
    let values: [Double]
    let color: Color

    var body: some View {
        SkyChart(
            points: values.enumerated().map { SkyChartPoint(index: $0.offset, value: $0.element) },
            tint: color,
            density: .sparkline,
            format: { $0.formatted(.number.precision(.fractionLength(2))) },
            accessibilityDescription: "\(symbol) intraday price"
        )
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
