import SwiftUI

/// Hotkey, launch-at-login, appearance, and network settings.
struct BehaviorSettingsView: View {
    @AppStorage("launchAtLogin") private var launchAtLogin: Bool = false
    @AppStorage("globalHotkey") private var globalHotkey: String = "cmd+shift+n"
    @AppStorage("popoverStaysOpen") private var popoverStaysOpen: Bool = false
    @AppStorage("requestTimeout") private var requestTimeout: Int = 30
    @AppStorage("resourceTimeout") private var resourceTimeout: Int = 120
    @AppStorage("maxRetries") private var maxRetries: Int = 3
    @State private var theme = ThemeManager.shared

    var body: some View {
        Form {
            Section {
                Picker("Theme", selection: $theme.appearance) {
                    ForEach(AppearanceMode.allCases) { mode in
                        Label(mode.label, systemImage: mode.icon).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                Text("System follows your macOS appearance setting.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Label("Appearance", systemImage: "circle.lefthalf.filled")
            }

            Section {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        updateLaunchAtLogin(enabled: newValue)
                    }
            } header: {
                Label("Startup", systemImage: "power")
            }

            Section {
                TextField("Hotkey", text: $globalHotkey)
                    .textFieldStyle(.roundedBorder)
                Text("Format: cmd+shift+n")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Label("Global Hotkey", systemImage: "keyboard")
            }

            Section {
                Stepper("Request timeout: \(requestTimeout)s", value: $requestTimeout, in: 10...120, step: 5)
                    .help("Time without data before a request times out")
                Stepper("Resource timeout: \(resourceTimeout)s", value: $resourceTimeout, in: 30...600, step: 30)
                    .help("Total time including retries")
                Stepper("Max retries: \(maxRetries)", value: $maxRetries, in: 0...10)
                    .help("Retry attempts for rate-limited and network errors")
                Text("Changes apply to new requests. Restart for full effect.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Label("Network", systemImage: "network")
            }

            Section {
                Toggle("Keep popover open on focus loss", isOn: $popoverStaysOpen)
            } header: {
                Label("Popover", systemImage: "rectangle.popup")
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private func updateLaunchAtLogin(enabled: Bool) {
        // Uses SMAppService on macOS 13+.
        // Implementation requires importing ServiceManagement.
        // For now, this is a placeholder that stores the preference.
    }
}
