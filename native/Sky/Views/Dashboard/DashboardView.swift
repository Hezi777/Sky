import SwiftUI

// The dashboard renders `config.visibleWidgets` IN ORDER, so reordering in
// Settings is reflected here directly. Widgets flow through a responsive
// waterfall; dense horizontal widgets use two columns when available. Hierarchy
// comes from size and order — no section headers.

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

/// Places stable `ForEach` children into the shortest available column range.
/// Layout changes never replace a widget's identity.
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
        let estimatedColumns = Int(
            (width + Tokens.cardGap) / (Tokens.dashboardGridTarget + Tokens.cardGap)
        )
        let columnCount = width < Tokens.dashboardGridBreakpoint
            ? 1
            : min(Tokens.dashboardGridMaxColumns, max(Tokens.dashboardWideColumnSpan, estimatedColumns))
        let columnWidth = max(
            Tokens.dashboardGridMinimum,
            (width - CGFloat(columnCount - 1) * Tokens.cardGap) / CGFloat(columnCount)
        )

        var items: [Placement] = []
        var columnHeights = Array(repeating: CGFloat.zero, count: columnCount)

        for index in subviews.indices {
            let subview = subviews[index]
            let requestedSpan = subview[WidgetSpanKey.self] == .wide
                ? Tokens.dashboardWideColumnSpan
                : 1
            let span = min(requestedSpan, columnCount)
            let column = shortestRangeStart(span: span, heights: columnHeights)
            let y = columnHeights[column..<(column + span)].max() ?? 0
            let itemWidth = CGFloat(span) * columnWidth + CGFloat(span - 1) * Tokens.cardGap
            let size = subview.sizeThatFits(ProposedViewSize(width: itemWidth, height: nil))
            let x = CGFloat(column) * (columnWidth + Tokens.cardGap)
            items.append(Placement(index: index, origin: CGPoint(x: x, y: y), size: size))
            let nextY = y + size.height + Tokens.cardGap
            for occupiedColumn in column..<(column + span) {
                columnHeights[occupiedColumn] = nextY
            }
        }

        let height = columnHeights.max() ?? 0
        return (items, height > 0 ? height - Tokens.cardGap : 0)
    }

    private func shortestRangeStart(span: Int, heights: [CGFloat]) -> Int {
        guard span < heights.count else { return 0 }

        return (0...(heights.count - span)).min { lhs, rhs in
            let lhsHeight = heights[lhs..<(lhs + span)].max() ?? 0
            let rhsHeight = heights[rhs..<(rhs + span)].max() ?? 0
            if lhsHeight == rhsHeight {
                let lhsVoid = heights[lhs..<(lhs + span)].reduce(0) { lhsHeight - $1 + $0 }
                let rhsVoid = heights[rhs..<(rhs + span)].reduce(0) { rhsHeight - $1 + $0 }
                if lhsVoid == rhsVoid { return lhs < rhs }
                return lhsVoid < rhsVoid
            }
            return lhsHeight < rhsHeight
        } ?? 0
    }

    private func naturalWidth(for subviews: Subviews) -> CGFloat {
        subviews.map { $0.sizeThatFits(.unspecified).width }.max() ?? Tokens.dashboardGridMinimum
    }
}
