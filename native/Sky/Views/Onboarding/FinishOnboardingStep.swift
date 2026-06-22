import SwiftUI

struct FinishOnboardingStep: View {
    let configuredCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.contentSpacing) {
            Label("Sky is ready", systemImage: "checkmark.seal.fill")
                .font(.title.weight(.semibold))
                .foregroundStyle(Tokens.accent)
            #if os(macOS)
            Text("\(configuredCount) integration settings are securely stored on this Mac.")
                .foregroundStyle(.secondary)
            #else
            Text("Local widgets are ready. Remote integrations remain unavailable on iOS.")
                .foregroundStyle(.secondary)
            #endif
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
