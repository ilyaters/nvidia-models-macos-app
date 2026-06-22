import SwiftUI

/// A compact theme toggle button with sun/moon/system icons.
///
/// Uses hierarchical SF Symbol rendering and Liquid Glass capsule background.
/// Clicking cycles through system → light → dark → system.
/// A menu is also available via right-click for direct selection.
struct ThemeToggleView: View {
    @State private var theme = ThemeManager.shared

    var body: some View {
        Menu {
            ForEach(AppearanceMode.allCases) { mode in
                Button {
                    theme.appearance = mode
                } label: {
                    Label(mode.label, systemImage: mode.icon)
                }
            }
        } label: {
            Image(systemName: theme.appearance.icon)
                .font(.system(size: 13))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.primary)
                .frame(width: 28, height: 24)
                .contentShape(Rectangle())
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
        .help(theme.appearance.tooltip)
        .onTapGesture {
            theme.cycle()
        }
    }
}
