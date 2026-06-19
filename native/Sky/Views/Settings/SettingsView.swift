import SwiftUI

// Settings: edit name + choose which widgets show (eye toggle) and reorder them.

struct SettingsView: View {
    @Environment(DashboardConfig.self) private var config
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var config = config

        NavigationStack {
            Form {
                Section("Profile") {
                    TextField("Name", text: $config.name)
                }

                Section {
                    ForEach(config.order) { kind in
                        WidgetToggleRow(kind: kind)
                    }
                    .onMove { config.move(from: $0, to: $1) }
                } header: {
                    Text("Widgets")
                } footer: {
                    Text("Tap the eye to show or hide a widget. Drag to reorder.")
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Settings")
            #if os(macOS)
            .frame(width: 420, height: 560)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
                #if os(iOS)
                ToolbarItem(placement: .topBarLeading) { EditButton() }
                #endif
            }
        }
    }
}

private struct WidgetToggleRow: View {
    @Environment(DashboardConfig.self) private var config
    let kind: WidgetKind

    var body: some View {
        let visible = config.isVisible(kind)
        HStack(spacing: 12) {
            Image(systemName: kind.symbol)
                .frame(width: 22)
                .foregroundStyle(visible ? Theme.accent : .secondary)
            Text(kind.title)
                .foregroundStyle(visible ? .primary : .secondary)
            Spacer()
            Button {
                withAnimation(.snappy) { config.toggle(kind) }
            } label: {
                Image(systemName: visible ? "eye" : "eye.slash")
                    .foregroundStyle(visible ? Theme.accent : .secondary)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(visible ? "Hide \(kind.title)" : "Show \(kind.title)")
        }
    }
}
