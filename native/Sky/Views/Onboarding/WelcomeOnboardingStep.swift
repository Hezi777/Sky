import SwiftUI

struct WelcomeOnboardingStep: View {
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Tokens.contentSpacing) {
                Label("Welcome to Sky", systemImage: "cloud.sun.fill")
                    .font(.title.weight(.semibold))
                Text("Your personal dashboard keeps integration credentials on this device in Keychain.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
