import SwiftUI
import SwiftData

/// Notification posted when the user requests a new chat via Cmd+N.
extension Notification.Name {
    static let newChatRequested = Notification.Name("newChatRequested")
}

/// Main application entry point.
///
/// Combines a main window (chat + metrics) with a menu bar popover
/// and a settings window.
@main
struct NvidiaLLMApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var theme = ThemeManager.shared

    /// Shared SwiftData container for conversations, messages, and usage records.
    let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try ModelContainer(
                for: Conversation.self, Message.self, UsageRecord.self,
                configurations: ModelConfiguration(
                    isStoredInMemoryOnly: false
                )
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        // Main window
        WindowGroup("NVIDIA LLM", id: "main") {
            ContentView()
                .modelContainer(modelContainer)
                .glassWindowBackground()
                .preferredColorScheme(theme.appearance.colorScheme)
                .animation(.snappy, value: theme.appearance)
        }
        .defaultSize(width: 1000, height: 650)
        .windowResizability(.contentMinSize)
        .commands {
            // Add New Chat shortcut
            CommandGroup(after: .newItem) {
                Button("New Chat") {
                    NotificationCenter.default.post(name: .newChatRequested, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }

        // Menu bar popover
        MenuBarController()
            .modelContainer(modelContainer)

        // Settings
        SettingsView()
            .modelContainer(modelContainer)
    }
}
