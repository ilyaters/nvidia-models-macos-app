import SwiftUI
import AppKit

/// NSVisualEffectView wrapper for native macOS vibrancy materials.
///
/// On macOS Tahoe (26+) the preferred approach is the `.glassEffect()`
/// modifier, but this view is retained for AppKit-interfacing contexts
/// (e.g. window backgrounds) where SwiftUI modifiers are not applicable.
struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .hudWindow
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
