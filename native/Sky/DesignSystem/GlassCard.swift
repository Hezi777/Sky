import SwiftUI

// The ONLY place Liquid Glass lives. `.glassEffect` must never appear outside
// DesignSystem/ — Views compose `GlassCard` or apply `glassSurface()`.
//
// Scope: glass is for hero / top chrome only. Widget cards stay opaque
// (`Card` / `WidgetShell`, `Tokens.cardFill`). Never switch a widget card to glass.
//
// Deployment target is macOS/iOS 26, so `.glassEffect` is always available — no
// material fallback branch needed.

/// The single glass container. Pads its content and floats it on native Liquid
/// Glass in a continuous rounded rectangle.
struct GlassCard<Content: View>: View {
    var cornerRadius: CGFloat = Tokens.cardRadius
    var padding: CGFloat = Tokens.cardPadding
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .glassSurface(in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

extension View {
    /// Native Liquid Glass behind this view, clipped to `shape`. The single glass
    /// entry point for hero chrome that isn't a full `GlassCard`.
    func glassSurface(
        in shape: some Shape = RoundedRectangle(cornerRadius: Tokens.cardRadius, style: .continuous)
    ) -> some View {
        glassEffect(.regular, in: shape)
    }
}
