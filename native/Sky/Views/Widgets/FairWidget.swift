import SwiftUI

struct FairWidget: View {
    // Israeli mutual fund number (Maya/TASE). Editable later via settings.
    @AppStorage("sky.fair.fund") private var fund = "5140785"

    var body: some View {
        AsyncCard(
            title: "Fund",
            symbol: "building.columns.fill",
            tint: Theme.accent,
            load: { [fund] in
                try await APIClient.shared.get("/api/fair", query: ["fund": fund]) as FairPrice
            }
        ) { fair in
            VStack(alignment: .leading, spacing: 8) {
                if let name = fair.fundName, !name.isEmpty {
                    Text(name)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Text(priceText(fair))
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    .monospacedDigit()
                    .contentTransition(.numericText(value: fair.price))
                    .animation(.snappy, value: fair.price)

                HStack(spacing: 8) {
                    if let asOf = asOfText(fair.asOf) {
                        Label(asOf, systemImage: "clock")
                    }
                    Spacer(minLength: 8)
                    Text(fair.source)
                        .foregroundStyle(.tertiary)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
    }

    private func priceText(_ fair: FairPrice) -> String {
        let symbol = symbol(for: fair.currency)
        let number = fair.price.formatted(.number.precision(.fractionLength(2)))
        return "\(symbol)\(number)"
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
