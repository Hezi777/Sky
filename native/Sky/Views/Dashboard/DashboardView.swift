import SwiftUI

// The dashboard: sky ambient, hero, then widget rows matching the web app's
// grid layout — Calendar + Tasks/Spotify prominent at top, IBKR + Fair next,
// then smaller widgets. No section headers; hierarchy comes from size.

struct DashboardView: View {
    @Environment(DashboardConfig.self) private var config
    @State private var now = Date()
    @State private var availableWidth: CGFloat = 0

    private var cloudState: CloudState {
        Cloud.state(for: CloudInput(hour: Calendar.current.component(.hour, from: now)))
    }

    /// Whether we have enough width for side-by-side columns.
    private var isWide: Bool { availableWidth >= 700 }

    var body: some View {
        ScrollView {
            ZStack(alignment: .top) {
                SkyAmbient(state: cloudState)

                VStack(spacing: Theme.gap) {
                    HeroZone(state: cloudState)

                    // Row 1: Calendar (wider) + Tasks & Spotify stacked
                    row1
                    // Row 2: IBKR (wider) + Fair
                    row2
                    // Row 3: Glance widgets — Quote, Weather, Countdown
                    row3
                    // Row 4: Stocks, GitHub, Reading, Strava
                    row4
                }
                .frame(maxWidth: 1500)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, Theme.gap)
                .padding(.bottom, Theme.gap * 2)
            }
        }
        .background(
            GeometryReader { geo in
                Color.clear.preference(key: WidthKey.self, value: geo.size.width)
            }
        )
        .onPreferenceChange(WidthKey.self) { availableWidth = $0 }
        .background(Color("BgBase"))
        .onAppear { now = Date() }
    }

    // MARK: - Row 1: Calendar + (Tasks / Spotify)

    @ViewBuilder
    private var row1: some View {
        let hasCalendar = config.isVisible(.calendar)
        let hasTasks = config.isVisible(.tasks)
        let hasSpotify = config.isVisible(.spotify)

        if hasCalendar || hasTasks || hasSpotify {
            if isWide {
                HStack(alignment: .top, spacing: Theme.gap) {
                    if hasCalendar {
                        CalendarWidget()
                            .frame(maxWidth: .infinity)
                    }
                    if hasTasks || hasSpotify {
                        VStack(spacing: Theme.gap) {
                            if hasTasks { TasksWidget() }
                            if hasSpotify { SpotifyWidget() }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(maxWidth: hasCalendar ? 380 : .infinity)
                    }
                }
            } else {
                VStack(spacing: Theme.gap) {
                    if hasCalendar { CalendarWidget() }
                    if hasTasks { TasksWidget() }
                    if hasSpotify { SpotifyWidget() }
                }
            }
        }
    }

    // MARK: - Row 2: IBKR + Fair

    @ViewBuilder
    private var row2: some View {
        let hasIbkr = config.isVisible(.ibkr)
        let hasFair = config.isVisible(.fair)

        if hasIbkr || hasFair {
            if isWide {
                HStack(alignment: .top, spacing: Theme.gap) {
                    if hasIbkr {
                        IBKRWidget()
                            .frame(maxWidth: .infinity)
                    }
                    if hasFair {
                        FairWidget()
                            .frame(maxWidth: .infinity)
                            .frame(maxWidth: hasIbkr ? 360 : .infinity)
                    }
                }
            } else {
                VStack(spacing: Theme.gap) {
                    if hasIbkr { IBKRWidget() }
                    if hasFair { FairWidget() }
                }
            }
        }
    }

    // MARK: - Row 3: Quote, Weather, Countdown (compact glance cards)

    @ViewBuilder
    private var row3: some View {
        let glanceWidgets: [WidgetKind] = [.quote, .weather, .countdown]
            .filter { config.isVisible($0) }

        if !glanceWidgets.isEmpty {
            let columns = responsiveColumns(
                count: glanceWidgets.count,
                minWidth: 250,
                maxWidth: 420
            )
            LazyVGrid(columns: columns, alignment: .leading, spacing: Theme.gap) {
                ForEach(glanceWidgets) { kind in
                    widget(for: kind)
                }
            }
        }
    }

    // MARK: - Row 4: Stocks, GitHub, Reading, Strava

    @ViewBuilder
    private var row4: some View {
        let extraWidgets: [WidgetKind] = [.stocks, .github, .reading, .strava]
            .filter { config.isVisible($0) }

        if !extraWidgets.isEmpty {
            let columns = responsiveColumns(
                count: extraWidgets.count,
                minWidth: 260,
                maxWidth: 420
            )
            LazyVGrid(columns: columns, alignment: .leading, spacing: Theme.gap) {
                ForEach(extraWidgets) { kind in
                    widget(for: kind)
                }
            }
        }
    }

    // MARK: - Helpers

    private func responsiveColumns(count: Int, minWidth: CGFloat, maxWidth: CGFloat) -> [GridItem] {
        let cols: Int
        if availableWidth < 560 {
            cols = 1
        } else {
            cols = min(count, max(1, Int(availableWidth / minWidth)))
        }
        return Array(
            repeating: GridItem(.flexible(minimum: minWidth, maximum: maxWidth), spacing: Theme.gap),
            count: max(1, cols)
        )
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

// MARK: - Preference key for reading scroll-view width

private struct WidthKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
