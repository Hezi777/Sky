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

                        if !DemoMode.isEnabled, !backendRuntime.state.isReady {
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
                                    // Hard-clamp every card to its exact tile height so a
                                    // content-tall widget can't render past its cell and
                                    // overlap the card below. Width stays flexible (the grid
                                    // sets it); height is fully determined by the size's rows.
                                    .frame(height: tileHeight(for: config.size(for: kind)))
                                    .clipped()
                                    .environment(\.widgetSize, config.size(for: kind))
                                    .layoutValue(
                                        key: WidgetSizeLayoutKey.self,
                                        value: config.size(for: kind)
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
                                        if kind.supportedSizes.count > 1 {
                                            Button("Resize") { config.cycleSize(kind) }
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
        .onAppear { now = DemoMode.adjustedNow }
        .task(id: loadIdentity) {
            guard !DemoMode.isEnabled else { return }
            guard backendRuntime.state.isReady else { return }
            await dashboardStore.loadVisible(
                config.visibleWidgets,
                configuredIntegrations: configuredIntegrationIDs
            )
        }
        .refreshable {
            guard !DemoMode.isEnabled else { return }
            guard backendRuntime.state.isReady else { return }
            await dashboardStore.refreshVisible(
                config.visibleWidgets,
                configuredIntegrations: configuredIntegrationIDs
            )
            now = Date()
        }
    }

    // MARK: - Rendered widgets

    /// Exact pixel height of a tile for the given size. Matches
    /// `GridDashboardLayout`'s row math so the clamped card and the reserved
    /// cell are identical — no overflow, no overlap.
    private func tileHeight(for size: WidgetSize) -> CGFloat {
        CGFloat(size.rows) * Tokens.dashboardRowUnit
            + CGFloat(size.rows - 1) * Tokens.cardGap
    }

    private var renderedWidgets: [WidgetKind] {
        if backendRuntime.state.isReady { return config.visibleWidgets }
        return config.visibleWidgets.filter(\.isLocalOnly)
    }

    private var unconfiguredVisibleWidgets: [WidgetKind] {
        guard !DemoMode.isEnabled else { return [] }
        return config.visibleWidgets.filter { kind in
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
        if !DemoMode.isEnabled, let integrationID = kind.integrationID,
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
            }
        }
    }
}
