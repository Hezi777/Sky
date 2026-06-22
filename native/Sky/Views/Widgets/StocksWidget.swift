import SwiftUI
import Charts

struct StocksWidget: View {
    @Environment(DashboardStore.self) private var store
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
                Button {
                    isEditing = true
                } label: {
                    Image(systemName: "pencil")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
            }
        ) { quotes in
            VStack(spacing: Tokens.contentSpacing) {
                ForEach(quotes) { StockRow(quote: $0) }
            }
        }
        .task(id: query) { await store.load(.stocks, force: true, stockSymbols: symbols) }
        .sheet(isPresented: $isEditing) {
            TickerEditor(tickersCSV: $tickersCSV)
        }
    }
}

private struct StockRow: View {
    let quote: StockQuote

    private var isUp: Bool { quote.changePercent >= 0 }
    private var changeColor: Color { isUp ? Tokens.positive : Tokens.negative }
    private var arrowSymbol: String { isUp ? "arrow.up.right" : "arrow.down.right" }

    var body: some View {
        Link(destination: URL(string: "https://finance.yahoo.com/quote/\(quote.symbol)") ?? URL(string: "https://finance.yahoo.com")!) {
            HStack(spacing: Tokens.rowSpacing) {
                Text(quote.symbol)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                if let spark = quote.spark, spark.count > 1 {
                    Sparkline(values: spark, color: changeColor)
                        .frame(width: Tokens.Size.artwork, height: Tokens.Size.stockSparklineHeight)
                }

                Spacer(minLength: Tokens.snug)

                Text(quote.price, format: .number.precision(.fractionLength(2)))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .contentTransition(.numericText())

                HStack(spacing: Tokens.badgePadding) {
                    Image(systemName: arrowSymbol)
                        .font(.caption2.weight(.bold))

                    Text(changeText)
                        .font(.caption.weight(.semibold))
                        .monospacedDigit()
                }
                .foregroundStyle(changeColor)
                .padding(.horizontal, Tokens.snug)
                .padding(.vertical, Tokens.badgePadding)
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
