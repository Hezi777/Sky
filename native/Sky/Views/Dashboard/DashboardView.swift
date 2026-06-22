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

                VStack(spacing: Theme.sectionGap) {
                    HeroZone(state: cloudState)

                    // Rows rebalanced by content size so short cards never sit
                    // stranded beside tall ones. Wide/dense widgets get width;
                    // small widgets are grouped together.
                    rowAgenda    // Calendar (wide) + Tasks
                    rowFinance   // Portfolio (wide) + Fund/Stocks
                    rowGitHub    // GitHub heatmap — full width (needs the room)
                    rowSmall     // Weather · Quote · Countdown (small, grouped)
                    rowSpotify   // Spotify — full width
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
        .ignoresSafeArea(.container, edges: .top)
        .background(Color("BgBase"))
        .onAppear { now = Date() }
    }

    // MARK: - Row: Agenda (Calendar wide + Tasks)

    @ViewBuilder
    private var rowAgenda: some View {
        let hasCalendar = config.isVisible(.calendar)
        let hasTasks = config.isVisible(.tasks)

        if hasCalendar || hasTasks {
            if isWide && hasCalendar && hasTasks {
                HStack(alignment: .top, spacing: Theme.cardGap) {
                    CalendarWidget()
                        .frame(maxWidth: .infinity)
                    TasksWidget()
                        .frame(maxWidth: .infinity)
                        .frame(maxWidth: 380)
                }
            } else {
                VStack(spacing: Theme.cardGap) {
                    if hasCalendar { CalendarWidget() }
                    if hasTasks { TasksWidget() }
                }
            }
        }
    }

    // MARK: - Row: Finance (Portfolio wide + Fund/Stocks stacked)

    @ViewBuilder
    private var rowFinance: some View {
        let hasIbkr = config.isVisible(.ibkr)
        let hasFair = config.isVisible(.fair)
        let hasStocks = config.isVisible(.stocks)

        if hasIbkr || hasFair || hasStocks {
            if isWide && hasIbkr && (hasFair || hasStocks) {
                HStack(alignment: .top, spacing: Theme.cardGap) {
                    IBKRWidget()
                        .frame(maxWidth: .infinity)
                    VStack(spacing: Theme.cardGap) {
                        if hasFair { FairWidget() }
                        if hasStocks { StocksWidget() }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(maxWidth: 400)
                }
            } else {
                VStack(spacing: Theme.cardGap) {
                    if hasIbkr { IBKRWidget() }
                    if hasFair { FairWidget() }
                    if hasStocks { StocksWidget() }
                }
            }
        }
    }

    // MARK: - Row: GitHub heatmap (full width; pairs with Strava if shown)

    @ViewBuilder
    private var rowGitHub: some View {
        let hasGithub = config.isVisible(.github)
        let hasStrava = config.isVisible(.strava)

        if isWide && hasGithub && hasStrava {
            HStack(alignment: .top, spacing: Theme.cardGap) {
                GitHubWidget()
                    .frame(maxWidth: .infinity)
                StravaWidget()
                    .frame(maxWidth: .infinity)
                    .frame(maxWidth: 360)
            }
        } else if hasGithub || hasStrava {
            VStack(spacing: Theme.cardGap) {
                if hasGithub { GitHubWidget() }
                if hasStrava { StravaWidget() }
            }
        }
    }

    // MARK: - Row: Small widgets, grouped (Weather · Quote · Countdown · Reading)

    @ViewBuilder
    private var rowSmall: some View {
        let kinds: [WidgetKind] = [.weather, .quote, .countdown, .reading]
            .filter { config.isVisible($0) }

        if !kinds.isEmpty {
            let columns = responsiveColumns(count: kinds.count, minWidth: 240)
            LazyVGrid(columns: columns, alignment: .leading, spacing: Theme.cardGap) {
                ForEach(kinds) { kind in
                    widget(for: kind)
                }
            }
        }
    }

    // MARK: - Row: Spotify (full width)

    @ViewBuilder
    private var rowSpotify: some View {
        if config.isVisible(.spotify) {
            SpotifyWidget()
        }
    }

    // MARK: - Helpers

    private func responsiveColumns(count: Int, minWidth: CGFloat) -> [GridItem] {
        let cols: Int
        if availableWidth < 560 {
            cols = 1
        } else {
            cols = min(count, max(1, Int(availableWidth / minWidth)))
        }
        // No maximum: flexible columns share the full width evenly, so rows fill
        // edge-to-edge with no trailing dead space.
        return Array(
            repeating: GridItem(.flexible(minimum: minWidth), spacing: Theme.cardGap),
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
