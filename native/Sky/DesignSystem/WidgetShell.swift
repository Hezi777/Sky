import SwiftUI

// The opaque widget foundation: one surface (`Card`), one header (`CardHeader`),
// and the composed shell every widget sits in (`WidgetShell`). All values come
// from `Tokens` — nothing raw here is meant to be repeated in Views.
//
// Glass never appears here: widget cards are opaque (`Tokens.cardFill`). For
// glass chrome use `GlassCard` / `glassSurface()` from GlassCard.swift.

// MARK: - Surface

/// Standard dashboard card surface. Bare container — add your own header via
/// `CardHeader`, or use `WidgetShell` to get header + content in one.
struct Card<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding(Tokens.cardPadding)
            // Hug content height: never stretch to match a taller neighbour in an
            // HStack/grid row. Short cards stay short — kills internal voids.
            .fixedSize(horizontal: false, vertical: true)
            .background(
                RoundedRectangle(cornerRadius: Tokens.cardRadius, style: .continuous)
                    .fill(Tokens.cardFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Tokens.cardRadius, style: .continuous)
                    .strokeBorder(Tokens.cardStroke, lineWidth: Tokens.cardStrokeWidth)
            )
            .shadow(color: Tokens.cardShadowColor, radius: Tokens.cardShadowRadius, y: Tokens.cardShadowY)
            .clipShape(RoundedRectangle(cornerRadius: Tokens.cardRadius, style: .continuous))
    }
}

// MARK: - Header

/// Consistent widget header: SF Symbol + title, optional trailing accessory.
struct CardHeader<Accessory: View>: View {
    let title: String
    let symbol: String
    var tint: Color = Tokens.textSecondary
    @ViewBuilder var accessory: Accessory

    // Header-internal geometry (DesignSystem-only constants, not Tokens).
    var body: some View {
        HStack(spacing: Tokens.headerSpacing) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .medium))
                .imageScale(.medium)
                .foregroundStyle(tint)
                .frame(
                    width: Tokens.Size.symbolBox,
                    height: Tokens.Size.symbolBox,
                    alignment: .center
                )
            Text(title)
                .font(Tokens.Font.widgetTitle)
                .foregroundStyle(.secondary)
            Spacer(minLength: Tokens.snug)
            accessory
        }
    }
}

extension CardHeader where Accessory == EmptyView {
    init(title: String, symbol: String, tint: Color = Tokens.textSecondary) {
        self.init(title: title, symbol: symbol, tint: tint) { EmptyView() }
    }
}

// MARK: - Shell

/// Header + content in the standard opaque card. The canonical widget container:
/// every widget body should be a `WidgetShell` (directly, or via `AsyncCard`).
struct WidgetShell<Accessory: View, Content: View>: View {
    let title: String
    let symbol: String
    var tint: Color = Tokens.textSecondary
    @ViewBuilder var accessory: Accessory
    @ViewBuilder var content: Content

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: Tokens.contentSpacing) {
                CardHeader(title: title, symbol: symbol, tint: tint) { accessory }
                content
            }
        }
    }
}

extension WidgetShell where Accessory == EmptyView {
    init(
        title: String,
        symbol: String,
        tint: Color = Tokens.textSecondary,
        @ViewBuilder content: () -> Content
    ) {
        self.init(title: title, symbol: symbol, tint: tint, accessory: { EmptyView() }, content: content)
    }
}

// MARK: - Loading / error states (per-widget, never crash the dashboard)

struct WidgetLoading: View {
    var body: some View {
        HStack(spacing: Tokens.snug) {
            ProgressView().controlSize(.small)
            Text("Loading…").font(.footnote).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: Tokens.Size.emptyStateHeight, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

struct WidgetError: View {
    let message: String
    var retry: (() -> Void)?

    var body: some View {
        VStack(spacing: Tokens.snug) {
            CloudAvatar(state: .droopy, role: .placeholder)
            Text(message)
                .font(Tokens.Font.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            if let retry {
                Button("Retry", action: retry)
                    .font(Tokens.Font.caption)
                    .foregroundStyle(.secondary)
                    .buttonStyle(.borderless)
            }
        }
        .frame(maxWidth: .infinity, minHeight: Tokens.Size.emptyStateHeight)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(message)
    }
}
