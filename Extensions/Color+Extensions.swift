import SwiftUI

extension Color {
    /// NVIDIA brand green.
    static let nvidiaGreen = Color(red: 0.46, green: 0.78, blue: 0.26)

    /// Subtle background for user message bubbles.
    static let userBubble = Color.accentColor.opacity(0.12)

    /// Subtle background for assistant message bubbles.
    static let assistantBubble = Color(nsColor: .controlBackgroundColor)
}
