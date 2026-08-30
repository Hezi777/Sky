import SwiftUI

/// Rounded-capsule progress bar shared by Reading and Spotify widgets.
/// `progress` is clamped to 0...1.
struct WidgetProgressBar: View {
    let progress: Double
    var tint: Color = Tokens.accent

    private var clampedProgress: Double { min(max(progress, 0), 1) }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.quaternary)

                Capsule()
                    .fill(tint)
                    .frame(width: proxy.size.width * clampedProgress)
            }
        }
        .frame(height: Tokens.Size.progressBarHeight)
        .accessibilityValue(Text("\(Int(clampedProgress * 100)) percent"))
    }
}

// MARK: - Preview

#Preview("WidgetProgressBar") {
    VStack(spacing: Tokens.contentSpacing) {
        WidgetProgressBar(progress: 0.72)
        WidgetProgressBar(progress: 0.35, tint: Tokens.positive)
        WidgetProgressBar(progress: 1.0, tint: Tokens.negative)
        WidgetProgressBar(progress: 0.0)
    }
    .padding(Tokens.cardPadding)
}
