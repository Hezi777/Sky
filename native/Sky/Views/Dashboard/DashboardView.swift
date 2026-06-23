import SwiftUI

// The dashboard renders `config.visibleWidgets` IN ORDER through a fixed-cell
// grid layout. Widgets flow as direct ForEach children keyed by WidgetKind —
// edit chrome is an overlay, never a wrapper, so widget @State is preserved.

// MARK: - Cell rect preference key

/// Collects each widget cell's frame (in the "dashboard" coordinate space)
/// for edit-mode hit-testing during drag-to-reorder.
private struct CellRectKey: PreferenceKey {
    static let defaultValue: [WidgetKind: CGRect] = [:]
    static func reduce(value: inout [WidgetKind: CGRect], nextValue: () -> [WidgetKind: CGRect]) {
        value.merge(nextValue()) { _, new in new }
    }
}

// MARK: - Dashboard view

struct DashboardView: View {
    @Environment(DashboardConfig.self) private var config
    @Environment(IntegrationConfigStore.self) private var integrationConfig
    @Environment(BackendRuntime.self) private var backendRuntime
    @Environment(DashboardStore.self) private var dashboardStore
    @Environment(DashboardEditState.self) private var editState
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

                        GridDashboardLayout {
                            ForEach(renderedWidgets) { kind in
                                widget(for: kind)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                                    .layoutValue(
                                        key: WidgetFootprintKey.self,
                                        value: effectiveFootprint(for: kind)
                                    )
                                    .layoutValue(
                                        key: WidgetDragOffsetKey.self,
                                        value: editState.draggedKind == kind
                                            ? editState.dragTranslation : .zero
                                    )
                                    .overlay { EditChromeOverlay(kind: kind) }
                                    .background {
                                        GeometryReader { proxy in
                                            Color.clear.preference(
                                                key: CellRectKey.self,
                                                value: [kind: proxy.frame(in: .named("dashboard"))]
                                            )
                                        }
                                    }
                                    .zIndex(editState.draggedKind == kind ? 1 : 0)
                                    .accessibilityActions {
                                        Button("Move up") { config.moveUp(kind) }
                                        Button("Move down") { config.moveDown(kind) }
                                        Button("Wider") {
                                            config.adjustFootprint(kind, dCols: 1, dRows: 0)
                                        }
                                        Button("Narrower") {
                                            config.adjustFootprint(kind, dCols: -1, dRows: 0)
                                        }
                                        Button("Taller") {
                                            config.adjustFootprint(kind, dCols: 0, dRows: 1)
                                        }
                                        Button("Shorter") {
                                            config.adjustFootprint(kind, dCols: 0, dRows: -1)
                                        }
                                    }
                            }
                        }
                        .coordinateSpace(.named("dashboard"))
                        .onPreferenceChange(CellRectKey.self) { rects in
                            editState.cellRects = rects
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

    // MARK: - Footprint resolution

    /// Returns the live preview footprint during resize, otherwise the persisted one.
    private func effectiveFootprint(for kind: WidgetKind) -> WidgetFootprint {
        if editState.resizingKind == kind, let preview = editState.previewFootprint {
            return preview
        }
        return config.footprint(for: kind)
    }

    // MARK: - Rendered widgets

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
