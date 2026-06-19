import SwiftUI

// The dashboard: a sky photo at the top that fades to black, a large centered
// hero (cloud + greeting + AI line) over it, then the widget grid. Mirrors the
// web Dashboard (SkyAmbient + HeroZone + grid).

struct DashboardView: View {
    @Environment(DashboardConfig.self) private var config
    @State private var now = Date()

    private var cloudState: CloudState {
        Cloud.state(for: CloudInput(hour: Calendar.current.component(.hour, from: now)))
    }

    private let columns = [GridItem(.adaptive(minimum: 300, maximum: 460), spacing: Theme.gap)]

    var body: some View {
        ScrollView {
            ZStack(alignment: .top) {
                SkyAmbient(state: cloudState)

                VStack(spacing: Theme.gap) {
                    HeroZone(state: cloudState)

                    LazyVGrid(columns: columns, alignment: .leading, spacing: Theme.gap) {
                        ForEach(config.visibleWidgets) { kind in
                            widget(for: kind)
                        }
                    }
                    .padding(.horizontal, Theme.gap)
                    .padding(.bottom, Theme.gap * 2)
                }
                .frame(maxWidth: 1120)
                .frame(maxWidth: .infinity)
            }
        }
        .background(Color("BgBase"))
        .onAppear { now = Date() }
    }

    @ViewBuilder
    private func widget(for kind: WidgetKind) -> some View {
        switch kind {
        case .calendar: CalendarWidget()
        case .tasks: TasksWidget()
        case .github: GitHubWidget()
        case .spotify: SpotifyWidget()
        case .ibkr: IBKRWidget()
        case .fair: FairWidget()
        case .reading: ReadingWidget()
        case .countdown: CountdownWidget()
        case .stocks: StocksWidget()
        case .weather: WeatherWidget()
        case .quote: QuoteWidget()
        case .strava: StravaWidget()
        }
    }
}

// MARK: - Hero greeting zone

struct HeroZone: View {
    @Environment(DashboardConfig.self) private var config
    let state: CloudState

    @State private var aiMessage: String?

    var body: some View {
        let greeting = Cloud.greeting(for: state, name: config.name)

        VStack(spacing: 20) {
            CloudAvatar(state: state, size: 150)

            VStack(spacing: 10) {
                Text(greeting.primary)
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.35), radius: 12, y: 2)

                Text(aiMessage ?? greeting.secondary)
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.82))
                    .shadow(color: .black.opacity(0.3), radius: 8, y: 1)
                    .frame(maxWidth: 480)
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 440)
        .padding(.top, 28)
        .padding(.horizontal, Theme.gap)
        .task(id: state) {
            let body = GreetingRequest(mood: state.rawValue)
            if let resp: GreetingResponse = try? await APIClient.shared.post("/api/ai/greeting", body: body) {
                withAnimation(.easeOut(duration: 0.3)) { aiMessage = resp.message }
            }
        }
    }
}
