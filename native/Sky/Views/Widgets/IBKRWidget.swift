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
            VStack(alignment: .leading, spacing: 16) {
                PortfolioHeader(summary: data.summary)
                HStack(alignment: .center, spacing: 16) {
                    PositionsDonut(positions: data.positions)
                        .frame(width: 110, height: 110)
                    VStack(spacing: 8) {
                        ForEach(data.positions.prefix(4)) { PositionRow(position: $0) }
                    }
                    .frame(maxWidth: .infinity)
                }
                if data.source == .flex {
                    Text("Flex snapshot")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }
}

// MARK: - Header

private struct PortfolioHeader: View {
    let summary: IbkrSummary

    private var gain: Bool { summary.unrealizedPnlPercent >= 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(summary.totalValue, format: .currency(code: "USD").precision(.fractionLength(0)))
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                .monospacedDigit()
                .contentTransition(.numericText(value: summary.totalValue))
                .animation(.snappy, value: summary.totalValue)
            HStack(spacing: 4) {
                Image(systemName: gain ? "arrow.up.right" : "arrow.down.right")
                Text(summary.unrealizedPnlPercent / 100, format: .percent.precision(.fractionLength(2)))
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(gain ? .green : .red)
        }
    }
}

// MARK: - Donut

private struct PositionsDonut: View {
    let positions: [IbkrPosition]

    var body: some View {
        Chart(positions) { pos in
            SectorMark(
                angle: .value("Value", pos.marketValue),
                innerRadius: .ratio(0.62),
                angularInset: 1.5
            )
            .cornerRadius(4)
            .foregroundStyle(by: .value("Ticker", pos.ticker))
        }
        .chartLegend(.hidden)
    }
}

// MARK: - Position row

private struct PositionRow: View {
    let position: IbkrPosition

    private var gain: Bool { position.pnlPercent >= 0 }

    var body: some View {
        HStack(spacing: 8) {
            Text(position.ticker)
                .font(.subheadline.weight(.medium))
                .lineLimit(1)
            Spacer(minLength: 8)
            Text(position.pnlPercent / 100, format: .percent.precision(.fractionLength(1)))
                .font(.caption.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(gain ? .green : .red)
        }
    }
}
