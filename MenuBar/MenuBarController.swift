import SwiftUI
import AppKit

/// Manages the menu bar item.
///
/// Provides a dropdown menu (right-click or click) with quick actions:
/// open main window, new chat, settings, quit. The popover chat is accessible
/// via the "Open Popover" item which opens the main window's chat tab.
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
///
/// Uses `openWindow` and `openSettings` environment values to open the main
/// window and settings respectively.
struct MenuBarMenu: View {
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openSettings) private var openSettings

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
        } label: {
            Label("New Chat", systemImage: "plus.message")
        }

        Divider()

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
