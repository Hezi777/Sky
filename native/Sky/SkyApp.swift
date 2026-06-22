import SwiftUI

@main
struct SkyApp: App {
    @State private var config = DashboardConfig()
    @State private var integrationConfig = IntegrationConfigStore()
    @State private var backendRuntime = BackendRuntime()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(config)
                .environment(integrationConfig)
                .environment(backendRuntime)
        }
        #if os(macOS)
        .defaultSize(width: 1040, height: 920)
        #endif
    }
}
