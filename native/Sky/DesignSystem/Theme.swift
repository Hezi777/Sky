import SwiftUI

// Design tokens + reusable surfaces. Calm, native, Apple-Health-adjacent.

enum Theme {
    // Spacing
    static let gap: CGFloat = 16
    static let cardPadding: CGFloat = 18
    static let cardRadius: CGFloat = 22

    // Accent — Sky blue, matches the web app's --primary.
    static let accent = Color(red: 0.15, green: 0.39, blue: 0.92) // #2563EB
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
                    .fill(.background.secondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                    .strokeBorder(.separator.opacity(0.5), lineWidth: 0.5)
            )
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
