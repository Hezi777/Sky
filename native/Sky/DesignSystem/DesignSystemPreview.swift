import SwiftUI

// Living reference for the foundation: tokens + primitives + two sample widgets,
// composed exactly the way real widgets should. Self-contained (no networking).

#Preview("Design System") {
    ScrollView {
        VStack(alignment: .leading, spacing: Tokens.sectionGap) {

            // Color tokens
            VStack(alignment: .leading, spacing: Tokens.sectionSpacing) {
                Text("Tokens").font(Tokens.Font.sectionHeader).textCase(.uppercase)
                    .foregroundStyle(.secondary)
                HStack(spacing: Tokens.cardGap) {
                    swatch("accent", Tokens.accent)
                    swatch("positive", Tokens.positive)
                    swatch("negative", Tokens.negative)
                    ForEach(Array(Tokens.chartPalette.enumerated()), id: \.offset) { i, c in
                        swatch("chart\(i + 1)", c)
                    }
                }
            }

            // Glass chrome (hero only) + opaque widget shell, side by side
            GlassCard {
                VStack(alignment: .leading, spacing: Tokens.sectionSpacing) {
                    Text("Good morning")
                        .font(Tokens.Font.primaryValue(size: 30))
                    Text("Liquid Glass — hero chrome only")
                        .font(Tokens.Font.caption).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Two sample widgets built on WidgetShell
            HStack(alignment: .top, spacing: Tokens.cardGap) {
                sampleValueWidget
                sampleListWidget
            }
        }
        .padding(Tokens.gap)
    }
    .background(Color("BgBase"))
}

// Sample 1: a "primary value" widget (Weather-shaped).
@MainActor private var sampleValueWidget: some View {
    WidgetShell(title: "Weather", symbol: "cloud.sun.fill", tint: Tokens.accent) {
        HStack(alignment: .firstTextBaseline, spacing: Tokens.sectionSpacing) {
            Text("21°").font(Tokens.Font.primaryValue(size: 48, weight: .thin))
            Text("Partly cloudy").font(Tokens.Font.bodyRow).foregroundStyle(.secondary)
        }
    }
}

// Sample 2: a list widget with rows + a header accessory (Tasks-shaped).
@MainActor private var sampleListWidget: some View {
    WidgetShell(title: "Tasks", symbol: "checklist", tint: Tokens.accent) {
        Text("3").font(Tokens.Font.bodyRowStrong).foregroundStyle(.secondary)
    } content: {
        VStack(alignment: .leading, spacing: Tokens.sectionSpacing) {
            ForEach(["Ship design system", "Review PR", "Standup"], id: \.self) { task in
                HStack(spacing: Tokens.sectionSpacing) {
                    Image(systemName: "circle").foregroundStyle(.tertiary)
                    Text(task).font(Tokens.Font.bodyRow)
                }
            }
        }
    }
}

@MainActor private func swatch(_ name: String, _ color: Color) -> some View {
    VStack(spacing: 4) {
        RoundedRectangle(cornerRadius: Tokens.mediaRadius, style: .continuous)
            .fill(color)
            .frame(width: 44, height: 44)
        Text(name).font(Tokens.Font.microLabel).foregroundStyle(.secondary)
    }
}
