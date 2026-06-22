import SwiftUI

#if os(macOS)
import AppKit
#endif

struct RootView: View {
    @Environment(IntegrationConfigStore.self) private var integrationConfig

    var body: some View {
        if integrationConfig.isOnboardingComplete {
            DashboardRootView()
        } else {
            OnboardingView(configStore: integrationConfig) {}
        }
    }
}

private struct DashboardRootView: View {
    @Environment(IntegrationConfigStore.self) private var integrationConfig
    @Environment(BackendRuntime.self) private var backendRuntime
    @State private var showingSettings = false

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
                        Button {
                            showingSettings = true
                        } label: {
                            Image(systemName: "slider.horizontal.3")
                                #if os(macOS)
                                .foregroundStyle(.white)
                                .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
                                #endif
                        }
                        .accessibilityLabel("Settings")
                    }
                }
                .sheet(isPresented: $showingSettings) {
                    SettingsView()
                }
        }
        .task(id: integrationConfig.configurationRevision) {
            await backendRuntime.start(environment: integrationConfig.environmentValues())
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
        .enableFullScreen()
        #endif
    }
}
