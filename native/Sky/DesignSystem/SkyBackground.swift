import SwiftUI

// Atmospheric app background — near-black base with soft blue glows in the top
// corners that fade to black toward the bottom. Mirrors the web app's body
// gradient (radial glows over var(--background)).
struct SkyBackground: View {
    var body: some View {
        ZStack {
            Color("BgBase")

            // Top-left primary glow.
            RadialGradient(
                colors: [Color("GlowPrimary").opacity(0.16), .clear],
                center: .init(x: 0.15, y: -0.05),
                startRadius: 0,
                endRadius: 620
            )

            // Top-right secondary glow.
            RadialGradient(
                colors: [Color("GlowSecondary").opacity(0.14), .clear],
                center: .init(x: 0.9, y: 0.02),
                startRadius: 0,
                endRadius: 560
            )

            // Depth: fade the lower half toward pure black.
            LinearGradient(
                colors: [.clear, .black.opacity(0.55)],
                startPoint: .center,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }
}
