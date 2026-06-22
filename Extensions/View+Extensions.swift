import SwiftUI

extension View {
    /// Applies a Liquid Glass background consistent with macOS Tahoe design.
    ///
    /// Uses the native `.glassEffect()` modifier on macOS 26+ (Tahoe).
    /// Falls back to `.ultraThinMaterial` on earlier versions.
    @ViewBuilder
    func glassBackground(cornerRadius: CGFloat = 12) -> some View {
        if #available(macOS 26, *) {
            self.glassEffect(in: .rect(cornerRadius: cornerRadius))
        } else {
            self.background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
            )
        }
    }

    /// Applies a Liquid Glass background with a capsule shape.
    @ViewBuilder
    func glassCapsuleBackground() -> some View {
        if #available(macOS 26, *) {
            self.glassEffect(in: .capsule)
        } else {
            self.background(
                Capsule()
                    .fill(.ultraThinMaterial)
            )
        }
    }

    /// Conditionally applies a modifier.
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
