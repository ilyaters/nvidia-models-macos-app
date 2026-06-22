import AppKit

/// Application delegate for window management and global hotkeys.
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Apply metrics retention on launch.
        // The actual SwiftData context is available via the main window's environment.
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            // Re-open the main window when clicking the dock icon.
            if let window = NSApp.windows.first(where: { $0.title == "NVIDIA LLM" }) {
                window.makeKeyAndOrderFront(self)
            } else {
                NSApp.sendAction(Selector(("showMainWindow:")), to: nil, from: nil)
            }
        }
        return true
    }
}
