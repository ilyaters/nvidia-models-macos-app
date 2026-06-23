import SwiftUI
import AppKit
import SwiftData

/// Manages the menu bar item.
///
/// Provides a dropdown menu with quick actions and a list of existing
/// conversations for quick switching.
struct MenuBarController: Scene {
    var body: some Scene {
        MenuBarExtra {
            MenuBarMenu()
        } label: {
            Image(systemName: "cpu")
                .symbolRenderingMode(.hierarchical)
        }
        .menuBarExtraStyle(.menu)
    }
}

/// The menu content shown when clicking the menu bar icon.
struct MenuBarMenu: View {
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openSettings) private var openSettings
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Conversation.updatedAt, order: .reverse) private var conversations: [Conversation]

    private var viewModel: ChatViewModel { ChatViewModel.shared }

    var body: some View {
        Button {
            openWindow(id: "main")
            NSApp.activate(ignoringOtherApps: true)
        } label: {
            Label("Open NVIDIA LLM", systemImage: "macwindow")
        }

        Button {
            openWindow(id: "main")
            NSApp.activate(ignoringOtherApps: true)
            viewModel.createNewConversation(modelContext: modelContext)
        } label: {
            Label("New Chat", systemImage: "plus.message")
        }

        Divider()

        // List of existing conversations
        if !conversations.isEmpty {
            ForEach(conversations.prefix(10)) { conversation in
                Button {
                    openWindow(id: "main")
                    NSApp.activate(ignoringOtherApps: true)
                    viewModel.currentConversation = conversation
                    viewModel.syncSettingsFromCurrentConversation()
                } label: {
                    HStack {
                        Image(systemName: viewModel.currentConversation?.id == conversation.id ? "bubble.left.fill" : "bubble.left")
                        Text(conversation.title)
                    }
                }
            }

            Divider()
        }

        Button {
            openSettings()
        } label: {
            Label("Settings…", systemImage: "gearshape")
        }

        Divider()

        Button {
            NSApp.activate(ignoringOtherApps: true)
        } label: {
            Label("Bring to Front", systemImage: "arrow.up.forward.app")
        }

        Button {
            NSApp.terminate(nil)
        } label: {
            Label("Quit NVIDIA LLM", systemImage: "power")
        }
        .keyboardShortcut("q")
    }
}
