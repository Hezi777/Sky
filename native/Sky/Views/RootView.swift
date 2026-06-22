import SwiftUI

struct RootView: View {
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            DashboardView()
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
        #if os(macOS)
        .frame(minWidth: 720, minHeight: 560)
        .enableFullScreen()
        #endif
    }
}
