import SwiftUI

/// Root view router that switches between Chat and Metrics tabs.
struct ContentView: View {
    @State private var selectedTab: Tab = .chat

    enum Tab: String, CaseIterable {
        case chat = "Chat"
        case metrics = "Metrics"
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            MainChatView()
                .tabItem {
                    Label("Chat", systemImage: "bubble.left.and.bubble.right")
                }
                .tag(Tab.chat)

            MetricsView()
                .tabItem {
                    Label("Metrics", systemImage: "chart.bar")
                }
                .tag(Tab.metrics)
        }
        .frame(minWidth: 800, minHeight: 500)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                ThemeToggleView()
            }
        }
    }
}
