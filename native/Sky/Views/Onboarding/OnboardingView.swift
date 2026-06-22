import SwiftUI

struct OnboardingView: View {
    @State private var model: OnboardingModel
    private let onComplete: () -> Void

    init(configStore: IntegrationConfigStore, onComplete: @escaping () -> Void) {
        _model = State(initialValue: OnboardingModel(configStore: configStore))
        self.onComplete = onComplete
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: Tokens.sectionGap) {
                OnboardingProgressSection(currentStep: model.step)
                OnboardingStepContent(model: model)
                Spacer()
                OnboardingNavigationSection(
                    canGoBack: model.canGoBack,
                    isLastStep: model.isLastStep,
                    completionFailed: model.completionFailed,
                    onBack: model.goBack,
                    onContinue: continueOnboarding,
                    onSkip: skipOnboarding
                )
            }
            .padding(Tokens.editorPadding)
            .navigationTitle("Set up Sky")
        }
        #if os(macOS)
        .frame(minWidth: Tokens.Size.rootMinWidth, minHeight: Tokens.Size.rootMinHeight)
        #endif
    }

    private func continueOnboarding() {
        if model.isLastStep {
            if model.complete() { onComplete() }
        } else {
            model.goForward()
        }
    }

    private func skipOnboarding() {
        if model.complete() { onComplete() }
    }
}

private struct OnboardingProgressSection: View {
    let currentStep: OnboardingStep

    var body: some View {
        ProgressView(
            value: Double(currentStep.rawValue + 1),
            total: Double(OnboardingStep.allCases.count)
        )
        .accessibilityLabel("Onboarding progress")
    }
}

private struct OnboardingStepContent: View {
    let model: OnboardingModel

    var body: some View {
        switch model.step {
        case .welcome:
            WelcomeOnboardingStep()
        case .importEnvironment:
            EnvironmentImportOnboardingStep(model: model)
        case .integrations:
            IntegrationChecklistOnboardingStep(configStore: model.configStore)
        case .aiPrivacy:
            AIPrivacyOnboardingStep(model: model)
        case .finish:
            FinishOnboardingStep(configuredCount: model.configStore.configuredKeyNames.count)
        }
    }
}

private struct OnboardingNavigationSection: View {
    let canGoBack: Bool
    let isLastStep: Bool
    let completionFailed: Bool
    let onBack: () -> Void
    let onContinue: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: Tokens.contentSpacing) {
            if completionFailed {
                Label("Sky couldn’t save your setup. Please try again.", systemImage: "exclamationmark.triangle")
                    .foregroundStyle(Tokens.negative)
            }
            HStack(spacing: Tokens.contentSpacing) {
                if canGoBack {
                    Button("Back", action: onBack)
                }
                Spacer()
                Button("Skip setup", action: onSkip)
                    .buttonStyle(.plain)
                Button(isLastStep ? "Finish" : "Continue", action: onContinue)
                    .buttonStyle(.borderedProminent)
            }
        }
    }
}
