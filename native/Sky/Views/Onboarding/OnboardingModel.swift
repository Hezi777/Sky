import Foundation
import Observation

enum OnboardingStep: Int, CaseIterable, Equatable {
    case welcome
    case importEnvironment
    case integrations
    case aiPrivacy
    case finish
}

@MainActor
@Observable
final class OnboardingModel {
    let configStore: IntegrationConfigStore
    var step: OnboardingStep = .welcome
    var isFileImporterPresented = false
    var isAIPrivacyOptedIn: Bool
    private(set) var importResult: IntegrationConfigImportResult?
    private(set) var importFailed = false
    private(set) var completionFailed = false

    init(configStore: IntegrationConfigStore) {
        self.configStore = configStore
        isAIPrivacyOptedIn = configStore.isAIPrivacyOptedIn
    }

    var canGoBack: Bool { step != .welcome }
    var isLastStep: Bool { step == .finish }

    func goBack() {
        guard let previous = OnboardingStep(rawValue: step.rawValue - 1) else { return }
        step = previous
    }

    func goForward() {
        guard let next = OnboardingStep(rawValue: step.rawValue + 1) else { return }
        step = next
    }

    func importFile(at url: URL) {
        do {
            importResult = try configStore.importEnvFile(at: url)
            importFailed = false
        } catch {
            importResult = nil
            importFailed = true
        }
    }

    func markImportFailed() {
        importResult = nil
        importFailed = true
    }

    func complete() -> Bool {
        do {
            try configStore.setAIPrivacyOptIn(isAIPrivacyOptedIn)
            try configStore.markOnboardingComplete()
            completionFailed = false
            return true
        } catch {
            completionFailed = true
            return false
        }
    }
}
