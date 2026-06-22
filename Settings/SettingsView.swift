import SwiftUI

/// Tabbed settings window.
struct SettingsView: Scene {
    var body: some Scene {
        Settings {
            TabView {
                APISettingsView()
                    .tabItem { Label("API", systemImage: "key.fill") }

                ModelSettingsView()
                    .tabItem { Label("Models", systemImage: "cpu") }

                SearchSettingsView()
                    .tabItem { Label("Search", systemImage: "magnifyingglass") }

                BehaviorSettingsView()
                    .tabItem { Label("Behavior", systemImage: "gearshape") }

                HistorySettingsView()
                    .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }

                MetricsSettingsView()
                    .tabItem { Label("Metrics", systemImage: "chart.bar") }

                AboutView()
                    .tabItem { Label("About", systemImage: "info.circle") }
            }
            .frame(width: 500, height: 400)
        }
    }
}
