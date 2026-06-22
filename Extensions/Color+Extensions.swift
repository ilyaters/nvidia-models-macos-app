import SwiftUI

extension ShapeStyle where Self == Color {
    /// NVIDIA brand green.
    static var nvidiaGreen: Color { Color(red: 0.46, green: 0.78, blue: 0.26) }
}

extension Color {
    /// Subtle background for user message bubbles.
    static let userBubble = Color.accentColor.opacity(0.12)

    /// Subtle background for assistant message bubbles.
    static let assistantBubble = Color(nsColor: .controlBackgroundColor)
}
