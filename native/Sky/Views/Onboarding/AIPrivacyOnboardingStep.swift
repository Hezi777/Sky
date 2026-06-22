import SwiftUI

struct AIPrivacyOnboardingStep: View {
    @Bindable var model: OnboardingModel

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.contentSpacing) {
            Text("AI privacy")
                .font(.title2.weight(.semibold))
            Text("AI features are optional. This preference is a placeholder until privacy controls are connected to the AI experience.")
                .foregroundStyle(.secondary)
            Toggle("Allow optional AI features", isOn: $model.isAIPrivacyOptedIn)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
