import SwiftUI

/// Labeled numeric pair for compact metric displays (IBKR P&L, Fair
/// invested/gain). The caller formats the value string.
struct WidgetMetric: View {
    let label: String
    let value: String
    var tint: Color?

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.extraTight) {
            Text(label)
                .font(Tokens.Font.sectionHeader)
                .foregroundStyle(.secondary)
            Text(value)
                .font(Tokens.Font.metricValue)
                .foregroundStyle(tint ?? .primary)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Preview

#Preview("WidgetMetric") {
    HStack(spacing: Tokens.contentSpacing) {
        WidgetMetric(label: "INVESTED", value: "$12,450")
        WidgetMetric(label: "GAIN", value: "+$1,230", tint: Tokens.positive)
        WidgetMetric(label: "LOSS", value: "-$340", tint: Tokens.negative)
    }
    .padding(Tokens.cardPadding)
}
