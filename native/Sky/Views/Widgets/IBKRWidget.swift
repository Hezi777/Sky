import SwiftUI
import Charts

struct IBKRWidget: View {
    var body: some View {
        AsyncCard(
            title: "Portfolio",
            symbol: "chart.pie.fill",
            tint: Theme.accent,
            load: { try await APIClient.shared.get("/api/ibkr") as IbkrResponse },
            isEmpty: { $0.positions.isEmpty },
            emptyText: "No positions"
        ) { data in
            let slices = AllocationSlice.make(from: data.positions)

            VStack(alignment: .leading, spacing: 16) {
                PortfolioHeader(summary: data.summary)

                HStack(alignment: .center, spacing: 16) {
                    AllocationDonut(slices: slices)
                        .frame(width: 120, height: 120)
                    AllocationLegend(slices: slices)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                PnlBars(positions: data.positions)

                PositionsList(positions: data.positions)

                if data.source == .flex {
                    Text(flexFooter(asOf: data.asOf))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }

    private func flexFooter(asOf: String?) -> String {
        guard let asOf, let date = ISO8601DateFormatter.parse(asOf) else {
            return "Flex snapshot"
        }
        return "Flex snapshot · as of \(date.formatted(date: .abbreviated, time: .omitted))"
    }
}

// MARK: - Header

private struct PortfolioHeader: View {
    let summary: IbkrSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(summary.totalValue, format: .currency(code: "USD").precision(.fractionLength(0)))
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                .monospacedDigit()
                .contentTransition(.numericText(value: summary.totalValue))
                .animation(.snappy, value: summary.totalValue)

            HStack(spacing: 14) {
                if let dayPnl = summary.dayPnl {
                    PnlBadge(
                        label: "Day P&L",
                        value: dayPnl,
                        format: .currency(code: "USD").precision(.fractionLength(0))
                    )
                }
                PnlBadge(
                    label: "Unrealized",
                    value: summary.unrealizedPnlPercent / 100,
                    format: .percent.precision(.fractionLength(2))
                )
            }
        }
    }
}

private struct PnlBadge<F: FormatStyle>: View where F.FormatInput == Double, F.FormatOutput == String {
    let label: String
    let value: Double
    let format: F

    private var gain: Bool { value >= 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            HStack(spacing: 3) {
                Image(systemName: gain ? "arrow.up.right" : "arrow.down.right")
                Text(value, format: format)
                    .monospacedDigit()
                    .contentTransition(.numericText(value: value))
                    .animation(.snappy, value: value)
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(gain ? .green : .red)
        }
    }
}

// MARK: - Allocation

private struct AllocationSlice: Identifiable {
    let ticker: String
    let value: Double
    let fraction: Double
    let color: Color
    var id: String { ticker }

    /// Top positions by market value (absolute), descending; remainder folded
    /// into "Other" — mirrors the web allocation donut.
    static func make(from positions: [IbkrPosition]) -> [AllocationSlice] {
        let sorted = positions.sorted { abs($0.marketValue) > abs($1.marketValue) }
        let top = sorted.prefix(5)
        let rest = sorted.dropFirst(5)

        var entries: [(String, Double)] = top.map { ($0.ticker, abs($0.marketValue)) }
        let restTotal = rest.reduce(0) { $0 + abs($1.marketValue) }
        if restTotal > 0 { entries.append(("Other", restTotal)) }

        let total = entries.reduce(0) { $0 + $1.1 }
        guard total > 0 else { return [] }

        return entries.enumerated().map { index, entry in
            AllocationSlice(
                ticker: entry.0,
                value: entry.1,
                fraction: entry.1 / total,
                color: Theme.chartColor(index)
            )
        }
    }
}

private struct AllocationDonut: View {
    let slices: [AllocationSlice]

    var body: some View {
        Chart(slices) { slice in
            SectorMark(
                angle: .value("Value", slice.value),
                innerRadius: .ratio(0.62),
                angularInset: 1.5
            )
            .cornerRadius(4)
            .foregroundStyle(slice.color)
        }
        .chartLegend(.hidden)
    }
}

private struct AllocationLegend: View {
    let slices: [AllocationSlice]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Allocation")
                .font(.caption2.weight(.semibold))
                .textCase(.uppercase)
                .foregroundStyle(.secondary)

            ForEach(slices) { slice in
                HStack(spacing: 6) {
                    Circle()
                        .fill(slice.color)
                        .frame(width: 8, height: 8)
                    Text(slice.ticker)
                        .font(.caption.weight(.medium))
                        .lineLimit(1)
                    Spacer(minLength: 6)
                    Text(slice.fraction, format: .percent.precision(.fractionLength(1)))
                        .font(.caption)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

// MARK: - P&L by position (bar chart)

private struct PnlBars: View {
    let positions: [IbkrPosition]

    var body: some View {
        let ranked = positions.sorted { $0.pnlPercent > $1.pnlPercent }

        VStack(alignment: .leading, spacing: 6) {
            Text("P&L by position")
                .font(.caption2.weight(.semibold))
                .textCase(.uppercase)
                .foregroundStyle(.secondary)

            Chart(ranked) { position in
                BarMark(
                    x: .value("P&L", position.pnlPercent),
                    y: .value("Ticker", position.ticker)
                )
                .cornerRadius(3)
                .foregroundStyle(position.pnlPercent >= 0 ? Color.green : Color.red)
                .annotation(position: position.pnlPercent >= 0 ? .trailing : .leading) {
                    Text(position.pnlPercent / 100, format: .percent.precision(.fractionLength(1)))
                        .font(.system(size: 9, weight: .medium))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks(position: .leading) {
                    AxisValueLabel().font(.caption2)
                }
            }
            .chartXScale(domain: pnlDomain(ranked))
            .frame(height: CGFloat(ranked.count) * 22 + 8)
        }
    }

    /// Symmetric-ish domain with headroom so the % annotations don't clip.
    private func pnlDomain(_ positions: [IbkrPosition]) -> ClosedRange<Double> {
        let values = positions.map(\.pnlPercent)
        let lo = min(0, values.min() ?? 0)
        let hi = max(0, values.max() ?? 0)
        let pad = max(4, (hi - lo) * 0.22)
        return (lo - pad)...(hi + pad)
    }
}

// MARK: - Positions list

private struct PositionsList: View {
    let positions: [IbkrPosition]

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                Text("Ticker").frame(maxWidth: .infinity, alignment: .leading)
                Text("Shares").frame(maxWidth: .infinity, alignment: .trailing)
                Text("Avg").frame(maxWidth: .infinity, alignment: .trailing)
                Text("Price").frame(maxWidth: .infinity, alignment: .trailing)
                Text("P&L").frame(maxWidth: .infinity, alignment: .trailing)
            }
            .font(.caption2)
            .foregroundStyle(.secondary)

            ForEach(positions) { PositionRow(position: $0) }
        }
    }
}

private struct PositionRow: View {
    let position: IbkrPosition

    private var gain: Bool { position.pnlPercent >= 0 }

    var body: some View {
        HStack(spacing: 8) {
            Text(position.ticker)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(position.shares, format: .number.precision(.fractionLength(0...2)))
                .frame(maxWidth: .infinity, alignment: .trailing)
            Text(position.avgCost, format: .currency(code: "USD").precision(.fractionLength(2)))
                .frame(maxWidth: .infinity, alignment: .trailing)
            Text(position.currentPrice, format: .currency(code: "USD").precision(.fractionLength(2)))
                .frame(maxWidth: .infinity, alignment: .trailing)
            Text(position.pnlPercent / 100, format: .percent.precision(.fractionLength(1)))
                .foregroundStyle(gain ? .green : .red)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .font(.caption)
        .monospacedDigit()
    }
}
