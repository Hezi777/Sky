import SwiftUI

@main
struct SkyApp: App {
    @State private var config = DashboardConfig()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(config)
        }
        #if os(macOS)
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 980, height: 720)
        #endif
    }
}
