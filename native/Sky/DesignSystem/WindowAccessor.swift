#if os(macOS)
import AppKit
import SwiftUI

/// Configures the hosting NSWindow for a transparent title bar that blends with
/// the sky background while keeping full-screen support (green traffic-light
/// button, View > Enter Full Screen, Control-Command-F).
///
/// `.windowStyle(.hiddenTitleBar)` hides the traffic lights and disables the
/// standard full-screen toggle on macOS 26, so we use the default window style
/// and configure the NSWindow directly instead.
final class WindowAccessorView: NSView {
    private var didConfigure = false

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard let window, !didConfigure else { return }
        didConfigure = true

        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.styleMask.insert(.fullSizeContentView)
        window.isMovableByWindowBackground = true
        window.collectionBehavior.insert(.fullScreenPrimary)
    }
}

struct WindowAccessor: NSViewRepresentable {
    func makeNSView(context: Context) -> WindowAccessorView {
        WindowAccessorView()
    }
    func updateNSView(_ nsView: WindowAccessorView, context: Context) {}
}

extension View {
    /// Attach to the root view to enable macOS full-screen support with a
    /// transparent title bar.
    func enableFullScreen() -> some View {
        background(WindowAccessor())
    }
}
#endif
