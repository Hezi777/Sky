import SwiftUI

/// Small pill badge for inline labels (Calendar "Now"/"All day", Fair
/// "live"/"manual", Task tags).
struct WidgetBadge: View {
    let text: String
    var color: Color = .secondary

    var body: some View {
        Text(text)
            .font(Tokens.Font.badge)
            .foregroundStyle(color)
            .padding(.horizontal, Tokens.headerSpacing)
            .padding(.vertical, Tokens.extraTight)
            .background(color.opacity(0.12), in: Capsule())
    }
}

// MARK: - Preview

#Preview("WidgetBadge") {
    HStack(spacing: Tokens.snug) {
        WidgetBadge(text: "Now", color: Tokens.accent)
        WidgetBadge(text: "All day")
        WidgetBadge(text: "Live", color: Tokens.positive)
        WidgetBadge(text: "Manual", color: Tokens.warning)
    }
    .padding(Tokens.cardPadding)
}
