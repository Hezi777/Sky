import SwiftUI

// Compact centered hero over the sky photo: cloud + greeting + concise summary.

struct HeroZone: View {
    @Environment(DashboardConfig.self) private var config
    let state: CloudState

    @State private var aiMessage: String?

    var body: some View {
        let greeting = Cloud.greeting(for: state, name: config.name)

        VStack(spacing: 10) {
            CloudAvatar(state: state, size: 118)

            VStack(spacing: 5) {
                Text(greeting.primary)
                    .font(.system(size: 30, weight: .semibold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.22), radius: 5, y: 1)

                Text(aiMessage ?? groundedFallback(for: state))
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.82))
                    .shadow(color: .black.opacity(0.18), radius: 3, y: 1)
                    .frame(maxWidth: 420)
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 220)
        .padding(.top, 8)
        .padding(.horizontal, Theme.gap)
        .task(id: state) {
            await fetchGreeting()
        }
    }

    private func groundedFallback(for state: CloudState) -> String {
        switch state {
        case .sleeping:
            return "Quiet mode. I'll keep things simple."
        case .stretching:
            return "Starting light. Here's the basic read."
        case .happy, .confident:
            return "Things look solid so far."
        case .droopy:
            return "A slower day. That's fine."
        case .calm:
            return "A steady day with not much noise."
        case .hero:
            return "Here's the day at a glance."
        }
    }

    private func fetchGreeting() async {
        // Gather safe, aggregated signals - never send dollar values or raw data.
        var commits: Int?
        var portfolioChange: Double?
        var nowPlaying: String?

        // GitHub: today's commit count
        if let github: GithubResponse = try? await APIClient.shared.get("/api/github") {
            let fmt = DateFormatter()
            fmt.dateFormat = "yyyy-MM-dd"
            fmt.timeZone = .current
            let todayStr = fmt.string(from: Date())
            commits = github.contributions.first(where: { $0.date == todayStr })?.count
        }

        // IBKR: portfolio day-change PERCENT only (no dollar values sent)
        if let ibkr: IbkrResponse = try? await APIClient.shared.get("/api/ibkr"),
           let dayPnl = ibkr.summary.dayPnl,
           ibkr.summary.totalValue > 0 {
            let base = ibkr.summary.totalValue - dayPnl
            if base > 0 {
                portfolioChange = ((dayPnl / base) * 1000).rounded() / 10
            }
        }

        // Spotify: only a coarse playback signal - no track metadata.
        if let spotify: SpotifyResponse = try? await APIClient.shared.get("/api/spotify"),
           let np = spotify.nowPlaying, np.isPlaying {
            nowPlaying = "music playing"
        }

        let request = GreetingRequest(
            commits: commits,
            portfolioChange: portfolioChange,
            nowPlaying: nowPlaying,
            mood: state.rawValue
        )

        if let resp: GreetingResponse = try? await APIClient.shared.post("/api/ai/greeting", body: request) {
            withAnimation(.easeOut(duration: 0.3)) { aiMessage = resp.message }
        }
    }
}
