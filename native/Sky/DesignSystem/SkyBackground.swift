import SwiftUI

// Atmospheric top-of-page sky photo that fades into the black background —
// mirrors the web SkyAmbient. The image changes with the cloud mood state and
// dissolves to transparent by ~halfway down (mask: opaque top → clear bottom).
struct SkyAmbient: View {
    let state: CloudState
    var height: CGFloat = 360

    var body: some View {
        Image(state.skyAssetName)
            .resizable()
            .scaledToFill()
            .frame(height: height)
            .frame(maxWidth: .infinity)
            .clipped()
            .saturation(state == .hero ? 0.7 : 1.0)
            .brightness(state == .hero ? -0.05 : 0.0)
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: .black, location: 0.0),
                        .init(color: .black, location: 0.40),
                        .init(color: .clear, location: 1.0),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .ignoresSafeArea(.container, edges: .top)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}
