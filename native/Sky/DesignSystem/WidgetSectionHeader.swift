import SwiftUI

/// Uppercased sub-section header inside a widget card.
struct WidgetSectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(Tokens.Font.sectionHeader)
            .textCase(.uppercase)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, Tokens.extraTight)
    }
}

// MARK: - Preview

#Preview("WidgetSectionHeader") {
    VStack(alignment: .leading, spacing: Tokens.contentSpacing) {
        WidgetSectionHeader(title: "Portfolio")
        WidgetSectionHeader(title: "Recent Activity")
    }
    .padding(Tokens.cardPadding)
}
