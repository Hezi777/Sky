import SwiftUI
import Charts

struct IBKRWidget: View {
    @Environment(DashboardStore.self) private var store
    @Environment(\.widgetSize) private var size

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
            portfolioContent(data: data)
        }
        .task { await store.load(.ibkr) }
    }

    @ViewBuilder
    private func portfolioContent(data: IbkrResponse) -> some View {
        let slices = AllocationSlice.make(from: data.positions)

        switch size {
        case .medium, .small:
            VStack(alignment: .leading, spacing: Tokens.contentSpacing) {
                PortfolioHeader(summary: data.summary)

                AllocationView(slices: slices)

                if data.source == .flex {
                    Text(flexFooter(asOf: data.asOf))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

        case .large:
            VStack(alignment: .leading, spacing: Tokens.contentSpacing) {
                PortfolioHeader(summary: data.summary)

                AllocationView(slices: slices)

                TopMovers(positions: data.positions)

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
        VStack(alignment: .leading, spacing: Tokens.sectionSpacing) {
            Text(summary.totalValue, format: .currency(code: "USD").precision(.fractionLength(0)))
                .font(.system(.title, design: .rounded).weight(.semibold).monospacedDigit())
                .contentTransition(.numericText(value: summary.totalValue))
                .animation(.snappy, value: summary.totalValue)

            HStack(spacing: Tokens.rowSpacing) {
                if let dayPnl = summary.dayPnl {
                    WidgetMetric(
                        label: "DAY P&L",
                        value: dayPnl.formatted(
                            .currency(code: "USD")
                            .precision(.fractionLength(0))
                            .sign(strategy: .always())
                        ),
                        tint: dayPnl >= 0 ? Tokens.positive : Tokens.negative
                    )
                }
                WidgetMetric(
                    label: "UNREALIZED",
                    value: (summary.unrealizedPnlPercent / 100).formatted(
                        .percent
                        .sign(strategy: .always())
                        .precision(.fractionLength(2))
                    ),
                    tint: summary.unrealizedPnlPercent >= 0 ? Tokens.positive : Tokens.negative
                )
            }
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

/// Donut plus its legend, sharing one hover selection.
///
/// The legend is the interactive surface rather than the donut: pointing at a
/// sector would mean either a drag gesture — which the editable grid already
/// owns for moving widgets — or aiming at a thin wedge. A legend row is a wide,
/// honest target, and it is the thing already carrying the ticker name.
private struct AllocationView: View {
    let slices: [AllocationSlice]

    @State private var highlighted: AllocationSlice.ID?

    private var selected: AllocationSlice? {
        slices.first { $0.id == highlighted }
    }

    var body: some View {
        HStack(alignment: .center, spacing: Tokens.contentSpacing) {
            AllocationDonut(slices: slices, highlighted: highlighted, selected: selected)
                .frame(width: Tokens.Size.portfolioChart, height: Tokens.Size.portfolioChart)

            AllocationLegend(slices: slices, highlighted: $highlighted)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .animation(Tokens.Chart.scrubAnimation, value: highlighted)
    }
}

private struct AllocationDonut: View {
    let slices: [AllocationSlice]
    let highlighted: AllocationSlice.ID?
    let selected: AllocationSlice?

    private var total: Double {
        slices.reduce(0) { $0 + $1.value }
    }

    var body: some View {
        Chart(slices) { slice in
            SectorMark(
                angle: .value("Value", slice.value),
                innerRadius: .ratio(Tokens.Chart.donutInnerRatio),
                angularInset: Tokens.Chart.donutInset
            )
            .cornerRadius(Tokens.barRadius)
            .foregroundStyle(slice.color)
            .opacity(highlighted == nil || highlighted == slice.id ? 1 : Tokens.Chart.unselectedOpacity)
        }
        .chartLegend(.hidden)
        .animation(Tokens.Chart.dataChangeAnimation, value: slices.map(\.value))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Portfolio allocation")
        .accessibilityValue(
            slices.map {
                "\($0.ticker) \($0.fraction.formatted(.percent.precision(.fractionLength(1))))"
            }.joined(separator: ", ")
        )
        .chartBackground { _ in
            // The hole reads the pointed-at holding, and falls back to the total.
            // Text stays in ink tokens — the colored sector carries identity.
            VStack(spacing: Tokens.microSpacing) {
                Text(selected?.ticker ?? "Total")
                    .font(Tokens.Font.microLabel)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                Text(
                    selected?.value ?? total,
                    format: .currency(code: "USD").precision(.fractionLength(0))
                )
                .font(Tokens.Font.metricValue)
                .foregroundStyle(selected == nil ? .secondary : .primary)
                .contentTransition(.numericText())
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            }
            .padding(.horizontal, Tokens.tight)
        }
    }
}

private struct AllocationLegend: View {
    let slices: [AllocationSlice]
    @Binding var highlighted: AllocationSlice.ID?

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.sectionSpacing) {
            WidgetSectionHeader(title: "Allocation")

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
                        .font(Tokens.Font.rowTrailingValue)
                        .foregroundStyle(.secondary)
                }
                // The row, not the swatch, is the target.
                .contentShape(Rectangle())
                .opacity(highlighted == nil || highlighted == slice.id ? 1 : Tokens.Chart.unselectedOpacity)
                .onHover { isHovering in
                    highlighted = isHovering ? slice.id : (highlighted == slice.id ? nil : highlighted)
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
            WidgetSectionHeader(title: "Top movers")

            ForEach(movers) { position in
                WidgetRow(title: position.ticker, showsDivider: false, trailing: {
                    Text(
                        (position.pnlPercent / 100).formatted(
                            .percent
                            .sign(strategy: .always())
                            .precision(.fractionLength(1))
                        )
                    )
                    .font(Tokens.Font.rowTrailingValue)
                    .foregroundStyle(position.pnlPercent >= 0 ? Tokens.positive : Tokens.negative)
                })
            }
        }
    }
}
