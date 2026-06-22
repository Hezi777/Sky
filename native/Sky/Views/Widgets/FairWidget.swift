import SwiftUI

struct FairWidget: View {
    // Israeli mutual fund number (Maya/TASE). Editable later via settings.
    @AppStorage("sky.fair.fund") private var fund = "5140785"

    var body: some View {
        AsyncCard(
            title: "Fund",
            symbol: "building.columns",
            tint: Tokens.accent,
            load: { [fund] in
                try await APIClient.shared.get("/api/fair", query: ["fund": fund]) as FairPrice
            }
        ) { fair in
            VStack(alignment: .leading, spacing: Tokens.rowSpacing) {
                if let name = fair.fundName, !name.isEmpty {
                    Text(name)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                HStack(alignment: .firstTextBaseline, spacing: Tokens.extraTight) {
                    Text(symbol(for: fair.currency))
                        .font(.system(.title, design: .rounded).weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(fair.price, format: .number.precision(.fractionLength(2)))
                        .font(.system(.largeTitle, design: .rounded).weight(.bold))
                        .monospacedDigit()
                        .contentTransition(.numericText(value: fair.price))
                        .animation(.snappy, value: fair.price)
                    Text("/ unit")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                }

                HStack(spacing: Tokens.snug) {
                    if let asOf = asOfText(fair.asOf) {
                        Label(asOf, systemImage: "clock")
                    }
                    Spacer(minLength: Tokens.snug)
                    Text(fair.source)
                        .font(.caption2.weight(.medium))
                        .padding(.horizontal, Tokens.headerSpacing)
                        .padding(.vertical, Tokens.extraTight)
                        .background(.secondary.opacity(0.12), in: Capsule())
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
    }

    private func symbol(for currency: String) -> String {
        switch currency.uppercased() {
        case "ILS": return "₪"
        case "USD": return "$"
        case "EUR": return "€"
        case "GBP": return "£"
        default: return "\(currency) "
        }
    }

    private func asOfText(_ iso: String) -> String? {
        guard let date = ISO8601DateFormatter.parse(iso) else { return nil }
        return "as of \(date.formatted(date: .abbreviated, time: .omitted))"
    }
}
