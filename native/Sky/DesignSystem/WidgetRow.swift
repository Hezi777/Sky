import SwiftUI

/// Canonical list row shared across Calendar, Tasks, Stocks, Fair,
/// Spotify, Reading, and IBKR widgets. Provides a consistent leading glyph,
/// title/subtitle pair, trailing accessory, and optional divider.
struct WidgetRow<Leading: View, Trailing: View>: View {
    let title: String
    var subtitle: String?
    var showsDivider: Bool
    @ViewBuilder var leading: () -> Leading
    @ViewBuilder var trailing: () -> Trailing

    /// Primary init — title first so call sites read naturally.
    init(
        title: String,
        subtitle: String? = nil,
        showsDivider: Bool = true,
        @ViewBuilder leading: @escaping () -> Leading,
        @ViewBuilder trailing: @escaping () -> Trailing
    ) {
        self.title = title
        self.subtitle = subtitle
        self.showsDivider = showsDivider
        self.leading = leading
        self.trailing = trailing
    }

    // Whether the caller provided a real leading view.
    private var hasLeading: Bool { Leading.self != EmptyView.self }

    var body: some View {
        VStack(spacing: Tokens.zeroSpacing) {
            HStack(spacing: Tokens.rowSpacing) {
                if hasLeading {
                    leading()
                        .frame(
                            width: Tokens.Size.activityIcon,
                            height: Tokens.Size.activityIcon,
                            alignment: .center
                        )
                }

                VStack(alignment: .leading, spacing: Tokens.extraTight) {
                    Text(title)
                        .font(Tokens.Font.bodyRow)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    if let subtitle {
                        Text(subtitle)
                            .font(Tokens.Font.rowSubtitle)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: Tokens.snug)

                trailing()
                    .multilineTextAlignment(.trailing)
            }
            .padding(.vertical, Tokens.snug)

            if showsDivider {
                Divider()
                    .padding(.leading, hasLeading ? Tokens.Size.activityIcon + Tokens.rowSpacing : 0)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Convenience initialisers

extension WidgetRow where Leading == EmptyView, Trailing == EmptyView {
    init(title: String, subtitle: String? = nil, showsDivider: Bool = true) {
        self.init(
            title: title,
            subtitle: subtitle,
            showsDivider: showsDivider,
            leading: { EmptyView() },
            trailing: { EmptyView() }
        )
    }
}

extension WidgetRow where Leading == EmptyView {
    init(
        title: String,
        subtitle: String? = nil,
        showsDivider: Bool = true,
        @ViewBuilder trailing: @escaping () -> Trailing
    ) {
        self.init(
            title: title,
            subtitle: subtitle,
            showsDivider: showsDivider,
            leading: { EmptyView() },
            trailing: trailing
        )
    }
}

extension WidgetRow where Trailing == EmptyView {
    init(
        title: String,
        subtitle: String? = nil,
        showsDivider: Bool = true,
        @ViewBuilder leading: @escaping () -> Leading
    ) {
        self.init(
            title: title,
            subtitle: subtitle,
            showsDivider: showsDivider,
            leading: leading,
            trailing: { EmptyView() }
        )
    }
}

// MARK: - Preview

#Preview("WidgetRow") {
    VStack(spacing: Tokens.zeroSpacing) {
        WidgetRow(title: "Morning standup", subtitle: "9:00 AM", leading: {
            Circle()
                .fill(Tokens.accent)
                .frame(width: Tokens.Size.eventBar, height: Tokens.Size.activityIcon)
        })

        WidgetRow(
            title: "AAPL",
            subtitle: "Apple Inc.",
            leading: {
                Circle()
                    .fill(Tokens.positive)
                    .frame(width: Tokens.Size.legendDot, height: Tokens.Size.legendDot)
            },
            trailing: {
                VStack(alignment: .trailing, spacing: Tokens.extraTight) {
                    Text("$189.42")
                        .font(Tokens.Font.rowTrailingValue)
                        .foregroundStyle(.primary)
                    Text("+1.23%")
                        .font(Tokens.Font.rowTrailingValue)
                        .foregroundStyle(Tokens.positive)
                }
            }
        )

        WidgetRow(title: "Buy groceries", showsDivider: false)
    }
    .padding(Tokens.cardPadding)
}
