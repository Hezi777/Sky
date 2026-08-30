import SwiftUI

// Compact centered hero over the sky photo: cloud + greeting + concise summary.

struct HeroZone: View {
    @Environment(DashboardConfig.self) private var config
    @Environment(DashboardStore.self) private var dashboardStore
    @Environment(IntegrationConfigStore.self) private var integrationConfig
    let state: CloudState

    @State private var aiSummary: DashboardSummary?

    var body: some View {
        let greeting = demoGreeting ?? Cloud.greeting(for: state, name: config.name)

        VStack(spacing: Tokens.snug) {
            CloudAvatar(state: state, role: .hero)

            VStack(spacing: Tokens.tight) {
                Text(greeting.primary)
                    .font(.system(size: 30, weight: .semibold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.22), radius: 5, y: 1)

                Text(aiSummary?.text ?? localSummary.text)
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.82))
                    .shadow(color: .black.opacity(0.18), radius: 3, y: 1)
                    .frame(maxWidth: Tokens.Size.heroTextMaxWidth)
                    .transition(.opacity)
            }
            .padding(Tokens.cardPadding)
            .glassSurface()
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: Tokens.Size.heroMinHeight)
        #if os(macOS)
        .padding(.top, Tokens.heroTopPadding)
        #else
        .padding(.top, Tokens.snug)
        #endif
        .padding(.horizontal, Tokens.gap)
        .task(id: dashboardStore.signals) {
            await refreshOptionalAISummary()
        }
    }

    private var localSummary: DashboardSummary {
        DashboardSummaryService.localSummary(for: dashboardStore.signals)
    }

    /// Capture variants are named by time of day, so their visible greeting
    /// should say that time explicitly rather than falling back to "Hey".
    private var demoGreeting: CloudGreeting? {
        guard DemoMode.isEnabled, let hour = DemoMode.hourOverride else { return nil }
        return CloudGreeting(
            primary: "\(Cloud.greetingWord(hour: hour)), \(config.name)",
            secondary: "Welcome to Sky."
        )
    }

    private func refreshOptionalAISummary() async {
        aiSummary = nil
        do {
            try await Task.sleep(for: .milliseconds(600))
        } catch {
            return
        }
        guard !Task.isCancelled else { return }
        let summary = await DashboardSummaryService.optionalAISummary(
            for: dashboardStore.signals,
            configuration: integrationConfig
        )
        guard !Task.isCancelled, let summary else { return }
        withAnimation(.easeOut(duration: 0.3)) { aiSummary = summary }
    }
}
