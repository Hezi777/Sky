import SwiftUI

// The dashboard: a hero greeting zone (cloud character) followed by an adaptive
// grid of the visible widgets, in the user's chosen order.

struct DashboardView: View {
    @Environment(DashboardConfig.self) private var config

    private let columns = [GridItem(.adaptive(minimum: 300, maximum: 460), spacing: Theme.gap)]

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.gap) {
                HeroZone()

                LazyVGrid(columns: columns, alignment: .leading, spacing: Theme.gap) {
                    ForEach(config.visibleWidgets) { kind in
                        widget(for: kind)
                    }
                }
            }
            .padding(Theme.gap)
            .frame(maxWidth: 1100)
            .frame(maxWidth: .infinity)
        }
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
    @State private var now = Date()

    private var hour: Int { Calendar.current.component(.hour, from: now) }
    private var cloudState: CloudState { Cloud.state(for: CloudInput(hour: hour)) }

    var body: some View {
        HStack(alignment: .center, spacing: Theme.gap) {
            CloudAvatar(state: cloudState, size: 92)

            VStack(alignment: .leading, spacing: 4) {
                Text("\(Cloud.greetingWord(hour: hour)), \(config.name)")
                    .font(.title2.weight(.semibold))
                Text(now, format: .dateTime.weekday(.wide).day().month(.wide))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
    }
}
