import SwiftUI

// Design tokens + reusable surfaces. Calm, native, Apple-Health-adjacent.

enum Theme {
    // Spacing
    static let gap: CGFloat = 16
    /// Gap between cards within a section. Deliberately tighter than `gap` (the
    /// page margin) so cards read as one connected group, not scattered tiles.
    static let cardGap: CGFloat = 12
    /// Gap between whole sections. Larger than `cardGap` so sections read as
    /// distinct grouped bands (visual hierarchy), not one flat list of tiles.
    static let sectionGap: CGFloat = 30
    static let cardPadding: CGFloat = 18
    static let cardRadius: CGFloat = 22

    /// Standard spacing inside a card's content VStack.
    static let contentSpacing: CGFloat = 12
    /// Spacing between a section label and its content (sub-sections).
    static let sectionSpacing: CGFloat = 6
    /// Corner radius for nested containers inside a card (e.g. repo/list rows).
    static let innerRadius: CGFloat = 12
    /// Corner radius for media thumbnails (album art, etc.).
    static let mediaRadius: CGFloat = 8

    // Accent — Sky blue, matches the web app's --primary (light/dark via asset).
    static let accent = Color("SkyPrimary")

    /// Ordered chart palette, mirrors the web --chart-1…5 (adapts light/dark).
    static let chartPalette: [Color] = [
        Color("Chart1"), Color("Chart2"), Color("Chart3"), Color("Chart4"), Color("Chart5"),
    ]

    /// GitHub contribution scale: index 0 = empty, 1…4 = increasing intensity.
    static let githubLevels: [Color] = [
        Color("GithubEmpty"), Color("Github1"), Color("Github2"), Color("Github3"), Color("Github4"),
    ]

    static func chartColor(_ index: Int) -> Color { chartPalette[index % chartPalette.count] }
}

// MARK: - Glass helper with graceful fallback

extension View {
    /// Liquid Glass on macOS/iOS 26, ultra-thin material elsewhere.
    @ViewBuilder
    func glassSurface(in shape: some Shape = RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)) -> some View {
        if #available(macOS 26, iOS 26, *) {
            self.glassEffect(.regular, in: shape)
        } else {
            self.background(.ultraThinMaterial, in: shape)
        }
    }
}

// MARK: - Card container

/// Standard dashboard card surface. Every widget body sits in one of these.
struct Card<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding(Theme.cardPadding)
            // Hug content height: never stretch to match a taller neighbour in an
            // HStack/grid row. This is what kills the internal voids and the
            // "Weather layered on top" look — short cards stay short.
            .fixedSize(horizontal: false, vertical: true)
            .background(
                RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                    .fill(Color("CardBg").opacity(0.92))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                    .strokeBorder(.white.opacity(0.06), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.18), radius: 14, y: 6)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
    }
}

// MARK: - Card header

/// Consistent widget header: SF Symbol + title, optional trailing accessory.
struct CardHeader<Accessory: View>: View {
    let title: String
    let symbol: String
    var tint: Color = .secondary
    @ViewBuilder var accessory: Accessory

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .medium))
                .imageScale(.medium)
                .foregroundStyle(tint)
                .frame(width: 18, height: 18, alignment: .center)
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer(minLength: 8)
            accessory
        }
    }
}

extension CardHeader where Accessory == EmptyView {
    init(title: String, symbol: String, tint: Color = .secondary) {
        self.init(title: title, symbol: symbol, tint: tint) { EmptyView() }
    }
}

// MARK: - Loading / error states (per-widget, never crash the dashboard)

struct WidgetLoading: View {
    var body: some View {
        HStack(spacing: 8) {
            ProgressView().controlSize(.small)
            Text("Loading…").font(.footnote).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 44)
    }
}

struct WidgetError: View {
    let message: String
    var retry: (() -> Void)?

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(message).font(.footnote).foregroundStyle(.secondary)
                .lineLimit(2)
            Spacer(minLength: 4)
            if let retry {
                Button("Retry", action: retry)
                    .font(.footnote)
                    .buttonStyle(.borderless)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 44)
    }
}
