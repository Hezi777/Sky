import SwiftUI

// Design tokens + reusable surfaces. Calm, native, Apple-Health-adjacent.

enum Theme {
    // Spacing
    static let gap: CGFloat = 16
    static let cardPadding: CGFloat = 18
    static let cardRadius: CGFloat = 22

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
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Theme.cardPadding)
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
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(tint)
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
