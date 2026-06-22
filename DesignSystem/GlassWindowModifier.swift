import SwiftUI

/// Modifier that applies a Liquid Glass background to a window's content.
///
/// On macOS Tahoe (26+) this leverages the native glass material for the
/// window background. On earlier versions it falls back to
/// `NSVisualEffectView` with `.hudWindow` material.
struct GlassWindowModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(macOS 26, *) {
            content
                .background(.ultraThinMaterial)
        } else {
            content
                .background(VisualEffectView(material: .hudWindow))
        }
    }
}

extension View {
    /// Applies a Liquid Glass window background.
    func glassWindowBackground() -> some View {
        modifier(GlassWindowModifier())
    }
}
