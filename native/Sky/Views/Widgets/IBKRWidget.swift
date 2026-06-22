import SwiftUI
import Charts

struct IBKRWidget: View {
    @Environment(DashboardStore.self) private var store

    var body: some View {
        AsyncCard(
            title: "Portfolio",
            symbol: "chart.pie",
            tint: Tokens.accent,
            state: store.ibkr,
            isEmpty: { $0.positions.isEmpty },
            emptyText: "No positions",
            reload: { await store.load(.ibkr, force: true) }
        ) { data in
            let slices = AllocationSlice.make(from: data.positions)

            VStack(alignment: .leading, spacing: Tokens.contentSpacing) {
                PortfolioHeader(summary: data.summary)

                HStack(alignment: .center, spacing: Tokens.contentSpacing) {
                    AllocationDonut(slices: slices)
                        .frame(width: Tokens.Size.portfolioChart, height: Tokens.Size.portfolioChart)
                    AllocationLegend(slices: slices)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                TopMovers(positions: data.positions)

                if data.source == .flex {
                    Text(flexFooter(asOf: data.asOf))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .task { await store.load(.ibkr) }
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
        VStack(alignment: .leading, spacing: Tokens.sectionSpacing) {
            Text(summary.totalValue, format: .currency(code: "USD").precision(.fractionLength(0)))
                .font(.system(.title, design: .rounded).weight(.semibold))
                .monospacedDigit()
                .contentTransition(.numericText(value: summary.totalValue))
                .animation(.snappy, value: summary.totalValue)

            HStack(spacing: Tokens.rowSpacing) {
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
        VStack(alignment: .leading, spacing: Tokens.microSpacing) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value, format: format)
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .contentTransition(.numericText(value: value))
                .animation(.snappy, value: value)
                .foregroundStyle(gain ? Tokens.positive : Tokens.negative)
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
        let top = sorted.prefix(4)
        let rest = sorted.dropFirst(4)

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
                color: Tokens.chartColor(index)
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
                innerRadius: .ratio(0.65),
                angularInset: Tokens.extraTight
            )
            .cornerRadius(Tokens.barRadius)
            .foregroundStyle(slice.color)
        }
        .chartLegend(.hidden)
        .chartBackground { _ in
            // Total label centered in the donut hole
            let total = slices.reduce(0) { $0 + $1.value }
            VStack(spacing: Tokens.microSpacing) {
                Text("Total")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundStyle(.tertiary)
                Text(total, format: .currency(code: "USD").precision(.fractionLength(0)))
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct AllocationLegend: View {
    let slices: [AllocationSlice]

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.sectionSpacing) {
            Text("Allocation")
                .font(.caption2.weight(.semibold))
                .textCase(.uppercase)
                .foregroundStyle(.secondary)

            ForEach(slices) { slice in
                HStack(spacing: Tokens.compact) {
                    Circle()
                        .fill(slice.color)
                        .frame(width: Tokens.Size.legendDot, height: Tokens.Size.legendDot)
                    Text(slice.ticker)
                        .font(.caption2.weight(.medium))
                        .lineLimit(1)
                    Spacer(minLength: Tokens.sectionSpacing)
                    Text(slice.fraction, format: .percent.precision(.fractionLength(1)))
                        .font(.caption2)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

// MARK: - Top movers

private struct TopMovers: View {
    let positions: [IbkrPosition]

    /// Top 3 positions by absolute P&L%, descending.
    private var movers: [IbkrPosition] {
        Array(positions.sorted { abs($0.pnlPercent) > abs($1.pnlPercent) }.prefix(3))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.compact) {
            Text("Top movers")
                .font(.caption2.weight(.semibold))
                .textCase(.uppercase)
                .foregroundStyle(.secondary)

            ForEach(movers) { position in
                HStack(spacing: Tokens.compact) {
                    Text(position.ticker)
                        .font(.caption2.weight(.semibold))
                        .lineLimit(1)
                    Spacer(minLength: Tokens.tight)
                    Text(position.pnlPercent / 100, format: .percent.precision(.fractionLength(1)))
                        .font(.caption2.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(position.pnlPercent >= 0 ? Tokens.positive : Tokens.negative)
                }
            }
        }
    }
}
