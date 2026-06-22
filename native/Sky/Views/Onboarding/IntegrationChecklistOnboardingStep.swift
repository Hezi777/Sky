import SwiftUI

struct IntegrationChecklistOnboardingStep: View {
    @Environment(BackendRuntime.self) private var backendRuntime
    @State private var model: IntegrationSetupModel

    init(configStore: IntegrationConfigStore) {
        _model = State(initialValue: IntegrationSetupModel(configStore: configStore))
    }

    var body: some View {
        #if os(macOS)
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.contentSpacing) {
                IntegrationSetupHeader()
                ForEach(model.configStore.integrationStatuses) { status in
                    IntegrationCredentialSection(
                        status: status,
                        validationState: model.validationStates[status.id, default: .idle],
                        saveFailed: model.saveFailedIntegrationID == status.id,
                        draftBinding: model.draftBinding,
                        onSave: { model.save(status) }
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .task {
            model.loadSavedValues()
        }
        .task(id: model.configStore.configurationRevision) {
            await backendRuntime.start(environment: model.configStore.environmentValues())
            if backendRuntime.state.isReady {
                await model.validateBackendConfiguration()
            }
        }
        #else
        RemoteIntegrationsUnavailableSection()
        #endif
    }
}

private struct IntegrationSetupHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.compact) {
            Text("Connect your services")
                .font(.title2.weight(.semibold))
            Text("Open a service, add its credentials, then save. Values stay in your Mac’s Keychain.")
                .font(Tokens.Font.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private struct IntegrationCredentialSection: View {
    let status: IntegrationConfigStatus
    let validationState: IntegrationValidationState
    let saveFailed: Bool
    let draftBinding: (String) -> Binding<String>
    let onSave: () -> Void

    var body: some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: Tokens.rowSpacing) {
                Text(setupHint)
                    .font(Tokens.Font.caption)
                    .foregroundStyle(.secondary)
                ForEach(status.keyNames.sorted(), id: \.self) { key in
                    IntegrationCredentialField(
                        key: key,
                        value: draftBinding(key),
                        hasSavedValue: status.configuredKeyNames.contains(key)
                    )
                }
                IntegrationSaveSection(
                    validationState: validationState,
                    saveFailed: saveFailed,
                    onSave: onSave
                )
            }
            .padding(.top, Tokens.rowSpacing)
        } label: {
            IntegrationStatusRow(
                name: status.name,
                isConfigured: status.isConfigured,
                validationState: validationState
            )
        }
        .padding(Tokens.contentSpacing)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: Tokens.cardRadius))
    }

    private var setupHint: String {
        switch status.id {
        case "tickTick": "Use an MCP token, access token, or username and password. Only one method is needed."
        case "stocks": "Finnhub is required. Twelve Data is optional."
        case "github": "A personal access token is required. Username is optional."
        case "ibkr": "Use Flex token and query ID, or a local gateway URL."
        default: "Add all listed values to enable this service."
        }
    }
}

private struct IntegrationCredentialField: View {
    let key: String
    @Binding var value: String
    let hasSavedValue: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.compact) {
            HStack {
                Text(fieldLabel)
                    .font(Tokens.Font.caption.weight(.medium))
                if !hasSavedValue {
                    Text("Not saved")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            if isSecret {
                SecureField(key, text: $value)
                    .textFieldStyle(.roundedBorder)
            } else {
                TextField(key, text: $value)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }

    private var fieldLabel: String {
        key.replacingOccurrences(of: "_", with: " ").capitalized
    }

    private var isSecret: Bool {
        ["KEY", "PASSWORD", "SECRET", "TOKEN"].contains { key.contains($0) }
    }
}

private struct IntegrationSaveSection: View {
    let validationState: IntegrationValidationState
    let saveFailed: Bool
    let onSave: () -> Void

    var body: some View {
        HStack(spacing: Tokens.rowSpacing) {
            Button("Save", action: onSave)
                .buttonStyle(.bordered)
            IntegrationValidationLabel(state: validationState, saveFailed: saveFailed)
        }
    }
}

private struct IntegrationValidationLabel: View {
    let state: IntegrationValidationState
    let saveFailed: Bool

    var body: some View {
        if saveFailed {
            Label("Couldn’t save", systemImage: "exclamationmark.triangle")
                .foregroundStyle(Tokens.negative)
        } else {
            switch state {
            case .idle:
                EmptyView()
            case .checking:
                Label("Checking local service…", systemImage: "arrow.triangle.2.circlepath")
                    .foregroundStyle(.secondary)
            case .configured:
                Label("Connected locally", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(Tokens.positive)
            case .missing(let keys):
                Label("Still missing \(keys.count) value(s)", systemImage: "exclamationmark.circle")
                    .foregroundStyle(.secondary)
            case .unavailable:
                Label("Local service unavailable", systemImage: "exclamationmark.circle")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct IntegrationStatusRow: View {
    let name: String
    let isConfigured: Bool
    let validationState: IntegrationValidationState

    var body: some View {
        HStack(spacing: Tokens.rowSpacing) {
            Image(systemName: isConfigured ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isConfigured ? Tokens.positive : .secondary)
            Text(name)
            Spacer()
            Text(statusText)
                .font(Tokens.Font.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var statusText: String {
        if validationState == .configured { return "Connected locally" }
        return isConfigured ? "Saved" : "Setup needed"
    }
}
