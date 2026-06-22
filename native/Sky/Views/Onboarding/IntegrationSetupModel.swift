import Observation
import SwiftUI

enum IntegrationValidationState: Equatable {
    case idle
    case checking
    case configured
    case missing([String])
    case unavailable
}

private struct BackendIntegrationStatus: Decodable {
    let configured: Bool
    let missing: [String]
}

private struct BackendIntegrationsStatusResponse: Decodable {
    let integrations: [String: BackendIntegrationStatus]
}

@MainActor
@Observable
final class IntegrationSetupModel {
    let configStore: IntegrationConfigStore
    private(set) var drafts: [String: String] = [:]
    private(set) var validationStates: [String: IntegrationValidationState] = [:]
    private(set) var saveFailedIntegrationID: String?

    init(configStore: IntegrationConfigStore) {
        self.configStore = configStore
    }

    func loadSavedValues() {
        for status in configStore.integrationStatuses {
            for key in status.keyNames where drafts[key] == nil {
                drafts[key] = (try? configStore.value(forKey: key)) ?? ""
            }
        }
    }

    func draftBinding(for key: String) -> Binding<String> {
        Binding(
            get: { self.drafts[key, default: ""] },
            set: { self.drafts[key] = $0 }
        )
    }

    func save(_ status: IntegrationConfigStatus) {
        do {
            try configStore.setValues(
                Dictionary(uniqueKeysWithValues: status.keyNames.map { ($0, drafts[$0, default: ""]) })
            )
            validationStates[status.id] = .checking
            saveFailedIntegrationID = nil
        } catch {
            saveFailedIntegrationID = status.id
        }
    }

    func validateBackendConfiguration() async {
        guard !configStore.integrationStatuses.isEmpty else { return }
        do {
            let response: BackendIntegrationsStatusResponse = try await APIClient.shared.get(
                "/api/integrations/status"
            )
            for status in configStore.integrationStatuses {
                guard let backendStatus = response.integrations[status.id] else {
                    validationStates[status.id] = .unavailable
                    continue
                }
                validationStates[status.id] = backendStatus.configured
                    ? .configured
                    : .missing(backendStatus.missing)
            }
        } catch {
            for status in configStore.integrationStatuses {
                validationStates[status.id] = .unavailable
            }
        }
    }
}
