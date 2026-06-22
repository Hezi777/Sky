import SwiftUI

// Settings: edit name + choose which widgets show (eye toggle) and reorder them.

struct SettingsView: View {
    @Environment(DashboardConfig.self) private var config
    @Environment(IntegrationConfigStore.self) private var integrationConfig
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var config = config

        NavigationStack {
            Form {
                Section("Profile") {
                    TextField("Name", text: $config.name)
                }

                IntegrationSettingsSection(config: integrationConfig) {
                    dismiss()
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
            .frame(width: Tokens.Size.settingsWidth, height: Tokens.Size.rootMinHeight)
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

private struct IntegrationSettingsSection: View {
    let config: IntegrationConfigStore
    let onRestart: () -> Void

    var body: some View {
        Section("Integrations") {
            LabeledContent("Configured", value: "\(configuredCount) of \(config.integrationStatuses.count)")
            Button("Run Setup Again") {
                if (try? config.restartOnboarding()) != nil {
                    onRestart()
                }
            }
        }
    }

    private var configuredCount: Int {
        config.integrationStatuses.count(where: \.isConfigured)
    }
}

private struct WidgetToggleRow: View {
    @Environment(DashboardConfig.self) private var config
    let kind: WidgetKind

    var body: some View {
        let visible = config.isVisible(kind)
        HStack(spacing: Tokens.contentSpacing) {
            Image(systemName: kind.symbol)
                .frame(width: Tokens.Size.activityIcon)
                .foregroundStyle(visible ? Tokens.accent : .secondary)
            Text(kind.title)
                .foregroundStyle(visible ? .primary : .secondary)
            Spacer()
            Button {
                withAnimation(.snappy) { config.toggle(kind) }
            } label: {
                Image(systemName: visible ? "eye" : "eye.slash")
                    .foregroundStyle(visible ? Tokens.accent : .secondary)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(visible ? "Hide \(kind.title)" : "Show \(kind.title)")
        }
    }
}
