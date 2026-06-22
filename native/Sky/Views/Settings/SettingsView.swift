import SwiftUI

// Focused control center: Appearance, Integrations, Dashboard layout,
// Privacy & AI, and Data — each section binds to real app state.

struct SettingsView: View {
    @Environment(DashboardConfig.self) private var config
    @Environment(IntegrationConfigStore.self) private var integrationConfig
    @Environment(\.dismiss) private var dismiss
    @AppStorage("sky.appearance") private var appearanceRaw = AppTheme.system.rawValue

    var body: some View {
        @Bindable var config = config

        NavigationStack {
            Form {
                Section("Profile") {
                    TextField("Name", text: $config.name)
                }

                AppearanceSettingsSection(appearanceRaw: $appearanceRaw)

                IntegrationSettingsSection(config: integrationConfig) {
                    dismiss()
                }

                DashboardLayoutSection()

                PrivacyAISettingsSection(config: integrationConfig)

                DataSettingsSection()
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

private struct AppearanceSettingsSection: View {
    @Binding var appearanceRaw: String

    var body: some View {
        Section("Appearance") {
            Picker("Theme", selection: $appearanceRaw) {
                ForEach(AppTheme.allCases) { theme in
                    Label(theme.title, systemImage: theme.symbol).tag(theme.rawValue)
                }
            }
            #if os(macOS)
            .pickerStyle(.segmented)
            #endif
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

private struct DashboardLayoutSection: View {
    @Environment(DashboardConfig.self) private var config

    var body: some View {
        Section {
            ForEach(config.order) { kind in
                WidgetToggleRow(kind: kind)
            }
            .onMove { config.move(from: $0, to: $1) }

            Button("Reset to Default Layout") {
                withAnimation(.snappy) { config.resetLayout() }
            }
        } header: {
            Text("Dashboard")
        } footer: {
            Text("Tap the eye to show or hide a widget. Drag to reorder.")
        }
    }
}

private struct PrivacyAISettingsSection: View {
    let config: IntegrationConfigStore

    private var aiOptIn: Binding<Bool> {
        Binding(
            get: { config.isAIPrivacyOptedIn },
            set: { try? config.setAIPrivacyOptIn($0) }
        )
    }

    var body: some View {
        Section {
            Toggle("Enhance summary with AI", isOn: aiOptIn)
        } header: {
            Text("Privacy & AI")
        } footer: {
            Text(
                config.isConfigured("groq")
                    ? "When on, only coarse, non-identifying signals are sent to Groq to refine your daily summary. Off keeps everything on-device."
                    : "Add a Groq API key in Integrations to enable AI summaries. Until then summaries stay fully on-device."
            )
        }
    }
}

private struct DataSettingsSection: View {
    @Environment(DashboardConfig.self) private var config

    var body: some View {
        Section {
            LabeledContent("Fund tracking", value: "Managed in the Fund widget")
        } header: {
            Text("Data")
        } footer: {
            Text("Fund contributions are stored on this device and can be imported or exported from the Fund widget.")
        }
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
