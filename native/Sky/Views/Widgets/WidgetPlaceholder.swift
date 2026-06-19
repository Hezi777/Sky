import SwiftUI

// Temporary body for widgets not yet implemented. Each XxxWidget starts as a
// placeholder; the build team replaces its body with the real implementation.
struct WidgetPlaceholder: View {
    let kind: WidgetKind

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                CardHeader(title: kind.title, symbol: kind.symbol)
                HStack {
                    Spacer()
                    Text("Coming soon")
                        .font(.footnote)
                        .foregroundStyle(.tertiary)
                    Spacer()
                }
                .frame(minHeight: 48)
            }
        }
    }
}
