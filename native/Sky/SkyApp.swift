import SwiftUI

@main
struct SkyApp: App {
    @State private var config = DashboardConfig()
    @State private var integrationConfig = IntegrationConfigStore()
    @State private var backendRuntime = BackendRuntime()
    @State private var dashboardStore = DashboardStore()
    @State private var fairStore = FairStore()
    @AppStorage("sky.appearance") private var appearanceRaw = AppTheme.system.rawValue

    private var appearance: AppTheme {
        AppTheme(rawValue: appearanceRaw) ?? .system
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(config)
                .environment(integrationConfig)
                .environment(backendRuntime)
                .environment(dashboardStore)
                .environment(fairStore)
                .preferredColorScheme(appearance.colorScheme)
                #if os(macOS)
                .background(DemoWindowSizer())
                #endif
        }
        #if os(macOS)
        .defaultSize(width: 1040, height: 920)
        #endif
    }
}
