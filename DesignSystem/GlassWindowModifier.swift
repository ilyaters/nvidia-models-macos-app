import SwiftUI
import AppKit

/// Modifier that applies a Liquid Glass background to a window's content.
///
/// On macOS Tahoe (26+) this makes the window background transparent and
/// applies the native glass material so the whole window has the translucent
/// Liquid Glass appearance matching the menu bar popover.
/// On earlier versions it falls back to `NSVisualEffectView` with
/// `.hudWindow` material and `.behindWindow` blending.
struct GlassWindowModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(macOS 26, *) {
            content
                .background(.windowBackground)
                .background(WindowBackgroundView())
        } else {
            content
                .background(WindowBackgroundView())
        }
    }
}

/// Makes the hosting window transparent so the vibrancy material shows through.
struct WindowBackgroundView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .hudWindow
        view.blendingMode = .behindWindow
        view.state = .active

        // Make the hosting window transparent so the vibrancy is visible.
        DispatchQueue.main.async {
            if let window = view.window {
                window.isOpaque = false
                window.backgroundColor = .clear
                window.titlebarAppearsTransparent = true
                window.titleVisibility = .hidden
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = .hudWindow
        nsView.blendingMode = .behindWindow
        nsView.state = .active

        if let window = nsView.window {
            window.isOpaque = false
            window.backgroundColor = .clear
            window.titlebarAppearsTransparent = true
        }
    }
}

extension View {
    /// Applies a Liquid Glass window background.
    func glassWindowBackground() -> some View {
        modifier(GlassWindowModifier())
    }
}
