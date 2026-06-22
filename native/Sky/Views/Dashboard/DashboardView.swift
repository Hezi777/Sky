import SwiftUI

// The dashboard renders `config.visibleWidgets` IN ORDER, so reordering in
// Settings is reflected here directly. `.regular` widgets flow into a responsive
// grid; `.full` widgets (GitHub heatmap, Spotify) break out to their own
// full-width row. Hierarchy comes from size and order — no section headers.

struct DashboardView: View {
    @Environment(DashboardConfig.self) private var config
    @Environment(IntegrationConfigStore.self) private var integrationConfig
    @Environment(BackendRuntime.self) private var backendRuntime
    @Environment(DashboardStore.self) private var dashboardStore
    @State private var now = Date()
    let onOpenSettings: () -> Void

    init(onOpenSettings: @escaping () -> Void = {}) {
        self.onOpenSettings = onOpenSettings
    }

    private var cloudState: CloudState {
        let signals = dashboardStore.signals
        return Cloud.state(for: CloudInput(
            hour: Calendar.current.component(.hour, from: now),
            githubCommits: signals.commitsToday ?? 0,
            tasksCompleted: signals.completedTaskCount,
            daysSinceActivity: signals.daysSinceExercise,
            portfolioChangePercent: signals.portfolioDayChangePercent
        ))
    }

    var body: some View {
        ScrollView {
            ZStack(alignment: .top) {
                SkyAmbient(state: cloudState)

                // One container so the hero's Liquid Glass blends as a single
                // surface with anything else glassed in the dashboard chrome.
                GlassEffectContainer {
                    VStack(spacing: Tokens.sectionGap) {
                        HeroZone(state: cloudState)

                        if !backendRuntime.state.isReady {
                            BackendStatusCard(
                                state: backendRuntime.state,
                                onRetry: retryBackend,
                                onOpenSettings: onOpenSettings
                            )
                        } else if !unconfiguredVisibleWidgets.isEmpty {
                            IntegrationSetupStatusCard(
                                count: unconfiguredVisibleWidgets.count,
                                onOpenSettings: onOpenSettings
                            )
                        }

                        DashboardWidgetLayout {
                            ForEach(renderedWidgets) { kind in
                                widget(for: kind)
                                    .layoutValue(key: WidgetSpanKey.self, value: kind.span)
                            }
                        }
                    }
                    .frame(maxWidth: Tokens.dashboardMaxWidth)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, Tokens.gap)
                    .padding(.bottom, Tokens.dashboardBottomPadding)
                }
            }
        }
        .ignoresSafeArea(.container, edges: .top)
        .background(Color("BgBase"))
        .onAppear { now = Date() }
        .task(id: loadIdentity) {
            guard backendRuntime.state.isReady else { return }
            await dashboardStore.loadVisible(
                config.visibleWidgets,
                configuredIntegrations: configuredIntegrationIDs
            )
        }
        .refreshable {
            guard backendRuntime.state.isReady else { return }
            await dashboardStore.refreshVisible(
                config.visibleWidgets,
                configuredIntegrations: configuredIntegrationIDs
            )
            now = Date()
        }
    }

    private var renderedWidgets: [WidgetKind] {
        if backendRuntime.state.isReady { return config.visibleWidgets }
        return config.visibleWidgets.filter(\.isLocalOnly)
    }

    private var unconfiguredVisibleWidgets: [WidgetKind] {
        config.visibleWidgets.filter { kind in
            guard let integrationID = kind.integrationID else { return false }
            return !integrationConfig.isConfigured(integrationID)
        }
    }

    private var configuredIntegrationIDs: Set<String> {
        Set(integrationConfig.integrationStatuses.filter(\.isConfigured).map(\.id))
    }

    private var loadIdentity: String {
        let widgets = config.visibleWidgets.map(\.rawValue).joined(separator: ",")
        let integrations = configuredIntegrationIDs.sorted().joined(separator: ",")
        return "\(backendRuntime.state)|\(widgets)|\(integrations)"
    }

    private func retryBackend() {
        Task {
            await backendRuntime.restart(environment: integrationConfig.environmentValues())
        }
    }

    @ViewBuilder
    private func widget(for kind: WidgetKind) -> some View {
        if let integrationID = kind.integrationID,
           !integrationConfig.isConfigured(integrationID) {
            WidgetSetupCard(kind: kind)
        } else {
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
}

// MARK: - Responsive widget flow

private struct WidgetSpanKey: LayoutValueKey {
    static let defaultValue: WidgetSpan = .regular
}

/// Places stable `ForEach` children in responsive columns while allowing selected
/// widgets to span a full row. Layout changes never replace a widget's identity.
private struct DashboardWidgetLayout: Layout {
    private struct Placement {
        let index: Int
        let origin: CGPoint
        let size: CGSize
    }

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let width = proposal.width ?? naturalWidth(for: subviews)
        let result = placements(for: subviews, width: width)
        return CGSize(width: width, height: result.height)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        for placement in placements(for: subviews, width: bounds.width).items {
            subviews[placement.index].place(
                at: CGPoint(x: bounds.minX + placement.origin.x, y: bounds.minY + placement.origin.y),
                anchor: .topLeading,
                proposal: ProposedViewSize(placement.size)
            )
        }
    }

    private func placements(for subviews: Subviews, width: CGFloat) -> (items: [Placement], height: CGFloat) {
        let columnCount = width < Tokens.dashboardGridBreakpoint
            ? 1
            : max(1, Int(width / Tokens.dashboardGridTarget))
        let columnWidth = max(
            Tokens.dashboardGridMinimum,
            (width - CGFloat(columnCount - 1) * Tokens.cardGap) / CGFloat(columnCount)
        )

        var items: [Placement] = []
        var y: CGFloat = 0
        var column = 0
        var rowHeight: CGFloat = 0
        var hasRows = false

        for index in subviews.indices {
            let subview = subviews[index]
            if subview[WidgetSpanKey.self] == .full {
                if column > 0 {
                    y += rowHeight + Tokens.cardGap
                    column = 0
                    rowHeight = 0
                }

                let size = subview.sizeThatFits(ProposedViewSize(width: width, height: nil))
                items.append(Placement(index: index, origin: CGPoint(x: 0, y: y), size: size))
                y += size.height + Tokens.cardGap
                hasRows = true
                continue
            }

            let size = subview.sizeThatFits(ProposedViewSize(width: columnWidth, height: nil))
            let x = CGFloat(column) * (columnWidth + Tokens.cardGap)
            items.append(Placement(index: index, origin: CGPoint(x: x, y: y), size: size))
            rowHeight = max(rowHeight, size.height)
            column += 1
            hasRows = true

            if column == columnCount {
                y += rowHeight + Tokens.cardGap
                column = 0
                rowHeight = 0
            }
        }

        if column > 0 {
            y += rowHeight + Tokens.cardGap
        }
        return (items, hasRows ? y - Tokens.cardGap : 0)
    }

    private func naturalWidth(for subviews: Subviews) -> CGFloat {
        subviews.map { $0.sizeThatFits(.unspecified).width }.max() ?? Tokens.dashboardGridMinimum
    }
}
