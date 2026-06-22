import SwiftUI

/// Manages the app's color scheme preference.
///
/// Supports three modes: system (follows macOS), light, and dark.
/// The preference is persisted in `AppSettings.appearance` and applied
/// via the `.preferredColorScheme` modifier.
enum AppearanceMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    /// The `ColorScheme` to apply, or `nil` to follow the system.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }

    /// SF Symbol icon for the toggle button.
    var icon: String {
        switch self {
        case .system: "circle.lefthalf.filled"
        case .light: "sun.max.fill"
        case .dark: "moon.stars.fill"
        }
    }

    /// Human-readable label.
    var label: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    /// Tooltip text for the toggle.
    var tooltip: String {
        switch self {
        case .system: "Follow system appearance"
        case .light: "Light mode"
        case .dark: "Dark mode"
        }
    }
}

/// Observable theme manager that reads/writes the appearance preference.
@Observable
final class ThemeManager {
    static let shared = ThemeManager()

    var appearance: AppearanceMode {
        didSet {
            AppSettings.shared.appearance = appearance.rawValue
        }
    }

    private init() {
        appearance = AppearanceMode(rawValue: AppSettings.shared.appearance) ?? .system
    }

    /// Cycles to the next appearance mode (system → light → dark → system).
    func cycle() {
        switch appearance {
        case .system: appearance = .light
        case .light: appearance = .dark
        case .dark: appearance = .system
        }
    }
}
