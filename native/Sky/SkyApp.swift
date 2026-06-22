import SwiftUI

@main
struct SkyApp: App {
    @State private var config = DashboardConfig()
    @State private var integrationConfig = IntegrationConfigStore()
    @State private var backendRuntime = BackendRuntime()
    @State private var dashboardStore = DashboardStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(config)
                .environment(integrationConfig)
                .environment(backendRuntime)
                .environment(dashboardStore)
        }
        #if os(macOS)
        .defaultSize(width: 1040, height: 920)
        #endif
    }
}
