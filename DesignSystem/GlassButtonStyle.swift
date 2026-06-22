import SwiftUI

/// A button style consistent with macOS Tahoe Liquid Glass design.
///
/// Uses hierarchical SF Symbols, system fonts, and the native glass
/// material for backgrounds. Falls back to standard materials on
/// earlier macOS versions.
struct GlassButtonStyle: ButtonStyle {
    var prominence: Prominence = .standard

    enum Prominence {
        case standard
        case prominent
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: prominence == .prominent ? .semibold : .regular))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(background)
            .foregroundStyle(foreground)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(duration: 0.2), value: configuration.isPressed)
    }

    @ViewBuilder
    private var background: some View {
        if prominence == .prominent {
            if #available(macOS 26, *) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.glass)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.accentColor.opacity(0.3))
                    )
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.accentColor)
            }
        } else {
            if #available(macOS 26, *) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.glass)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.quaternary.opacity(0.5))
            }
        }
    }

    private var foreground: Color {
        prominence == .prominent ? .primary : .primary
    }
}
