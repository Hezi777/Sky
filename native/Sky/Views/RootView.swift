import SwiftUI

#if os(macOS)
import AppKit
#endif

struct RootView: View {
    @Environment(IntegrationConfigStore.self) private var integrationConfig

    var body: some View {
        if DemoMode.isEnabled || integrationConfig.isOnboardingComplete {
            DashboardRootView()
        } else {
            OnboardingView(configStore: integrationConfig) {}
        }
    }
}

private struct DashboardRootView: View {
    @Environment(IntegrationConfigStore.self) private var integrationConfig
    @Environment(DashboardConfig.self) private var config
    @Environment(BackendRuntime.self) private var backendRuntime
    @Environment(DashboardStore.self) private var dashboardStore
    @State private var showingSettings = false
    @State private var editState = DashboardEditState()
    @State private var showingHiddenWidgets = false

    var body: some View {
        NavigationStack {
            DashboardView {
                showingSettings = true
            }
                .navigationTitle("Sky")
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                #if os(macOS)
                .toolbarBackground(.hidden, for: .windowToolbar)
                #endif
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        HStack(spacing: Tokens.snug) {
                            if editState.isEditing {
                                hiddenWidgetsMenu
                            }

                            editLayoutButton

                            if !editState.isEditing {
                                settingsButton
                            }
                        }
                    }
                }
                .sheet(isPresented: $showingSettings) {
                    SettingsView()
                }
        }
        .environment(editState)
        .task(id: integrationConfig.configurationRevision) {
            if DemoMode.isEnabled {
                backendRuntime.enableDemo()
                dashboardStore.loadDemoFixtures()
            } else {
                await backendRuntime.start(environment: integrationConfig.environmentValues())
            }
        }
        .onDisappear {
            backendRuntime.stop()
        }
        #if os(macOS)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)) { _ in
            backendRuntime.stop()
        }
        #endif
        #if os(macOS)
        .frame(minWidth: Tokens.Size.rootMinWidth, minHeight: Tokens.Size.rootMinHeight)
        .windowToolbarFullScreenVisibility(.onHover)
        .enableFullScreen()
        #endif
    }

    // MARK: - Toolbar controls

    private var editLayoutButton: some View {
        Button {
            withAnimation(.spring(duration: 0.35, bounce: 0.15)) {
                editState.isEditing.toggle()
            }
        } label: {
            Image(systemName: editState.isEditing ? "checkmark.circle" : "square.grid.2x2")
                #if os(macOS)
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.3), radius: Tokens.extraTight, y: Tokens.microSpacing)
                #endif
        }
        .accessibilityLabel(editState.isEditing ? "Done editing" : "Edit layout")
    }

    private var settingsButton: some View {
        Button {
            showingSettings = true
        } label: {
            Image(systemName: "slider.horizontal.3")
                #if os(macOS)
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.3), radius: Tokens.extraTight, y: Tokens.microSpacing)
                #endif
        }
        .accessibilityLabel("Settings")
    }

    @ViewBuilder
    private var hiddenWidgetsMenu: some View {
        let hiddenKinds = WidgetKind.allCases.filter { config.hidden.contains($0) }
        if !hiddenKinds.isEmpty {
            Menu {
                ForEach(hiddenKinds) { kind in
                    Button {
                        withAnimation(.spring(duration: 0.35, bounce: 0.15)) {
                            config.toggle(kind)
                        }
                    } label: {
                        Label(kind.title, systemImage: kind.symbol)
                    }
                }
            } label: {
                Image(systemName: "plus.circle")
                    #if os(macOS)
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.3), radius: Tokens.extraTight, y: Tokens.microSpacing)
                    #endif
            }
            .accessibilityLabel("Show hidden widgets")
        }
    }
}
