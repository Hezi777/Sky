import SwiftUI

/// Compact Liquid Glass button for interactive controls. The sanctioned glass
/// control primitive alongside `GlassCard` and `glassSurface()`.
///
/// Use for toolbar-style actions (add, settings, import/export) — NOT for
/// content surfaces. Follows Apple HIG: glass on interactive chrome only.
struct GlassButton: View {
    private let label: AnyView
    private let action: () -> Void

    private static let capsuleRadius: CGFloat = Tokens.innerRadius

    // MARK: - Initialisers

    /// Text-only glass button.
    init(_ title: String, action: @escaping () -> Void) {
        self.label = AnyView(Text(title).font(Tokens.Font.bodyRow))
        self.action = action
    }

    /// Icon-only glass button.
    init(systemImage: String, accessibilityLabel: String, action: @escaping () -> Void) {
        self.label = AnyView(
            Image(systemName: systemImage)
                .font(.system(size: Tokens.Size.compactControl, weight: .medium))
                .accessibilityLabel(accessibilityLabel)
        )
        self.action = action
    }

    /// Icon + text glass button.
    init(_ title: String, systemImage: String, action: @escaping () -> Void) {
        self.label = AnyView(
            HStack(spacing: Tokens.tight) {
                Image(systemName: systemImage)
                    .font(.system(size: Tokens.Size.compactControl, weight: .medium))
                Text(title).font(Tokens.Font.bodyRow)
            }
        )
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            label
                .padding(.horizontal, Tokens.snug)
                .padding(.vertical, Tokens.compact)
                .glassSurface(in: Capsule())
        }
        .buttonStyle(.plain)
    }
}
