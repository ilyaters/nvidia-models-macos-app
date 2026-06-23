import SwiftUI
import AppKit

/// Modifier that applies a Liquid Glass background to a window's content.
///
/// On macOS Tahoe (26+) this makes the window background transparent and
/// applies the native glass material so the whole window has the translucent
/// Liquid Glass appearance.
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
///
/// Window properties are set only once in `makeNSView` to avoid performance
/// issues from repeated updates.
struct WindowBackgroundView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .hudWindow
        view.blendingMode = .behindWindow
        view.state = .active

        // Make the hosting window transparent so the vibrancy is visible.
        // Use a delayed async call to ensure the window is available.
        DispatchQueue.main.async { [weak view] in
            guard let view, let window = view.window else { return }
            window.isOpaque = false
            window.backgroundColor = .clear
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.animationBehavior = .documentWindow
        }
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        // Only update material/blending if they changed — avoid touching
        // window properties on every update for performance.
        if nsView.material != .hudWindow {
            nsView.material = .hudWindow
        }
        if nsView.blendingMode != .behindWindow {
            nsView.blendingMode = .behindWindow
        }
    }
}

extension View {
    /// Applies a Liquid Glass window background.
    func glassWindowBackground() -> some View {
        modifier(GlassWindowModifier())
    }
}
