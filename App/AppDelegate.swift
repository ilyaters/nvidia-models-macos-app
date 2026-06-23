import AppKit
import HotKey

/// Application delegate for window management, main menu, and global hotkeys.
///
/// Installs a minimal `NSApp.mainMenu` so the app has a proper top-screen menu
/// bar (App menu with About / Settings… / Quit) even when built as a bare
/// executable. This also provides a responder for `showSettingsWindow:` and
/// `Cmd+,`, and registers the global hotkey declared in `AppSettings`.
final class AppDelegate: NSObject, NSApplicationDelegate {

    /// Currently registered global hotkey. Kept as a property so it is retained
    /// for the lifetime of the app (otherwise it would be deallocated and stop
    /// working immediately).
    private var globalHotKey: HotKey?

    func applicationDidFinishLaunching(_ notification: Notification) {
        installMainMenu()
        registerGlobalHotkey()
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

    // MARK: - Main Menu

    /// Builds and installs a minimal application main menu.
    ///
    /// SwiftUI normally auto-generates this menu for bundled apps, but a bare
    /// SPM executable has none. Without it there is no "Settings…" item and no
    /// responder for `showSettingsWindow:` / `Cmd+,`.
    private func installMainMenu() {
        let mainMenu = NSMenu()

        // App menu (named after the app).
        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)
        let appMenu = NSMenu()
        appMenuItem.submenu = appMenu

        let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "NVIDIA LLM"

        appMenu.addItem(withTitle: "About \(appName)", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")

        appMenu.addItem(NSMenuItem.separator())

        // Settings… — opens the SwiftUI Settings scene. Uses a string-based
        // selector because `showSettingsWindow:` is not a publicly declared
        // `NSApplication` method; `nil` target walks the responder chain, where
        // SwiftUI registers the handler for the `Settings` scene.
        appMenu.addItem(withTitle: "Settings…", action: Selector(("showSettingsWindow:")), keyEquivalent: ",")

        appMenu.addItem(NSMenuItem.separator())

        appMenu.addItem(withTitle: "Hide \(appName)", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")

        let hideOthers = appMenu.addItem(withTitle: "Hide Others", action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h")
        hideOthers.keyEquivalentModifierMask = [.command, .option]

        appMenu.addItem(withTitle: "Show All", action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: "")

        appMenu.addItem(NSMenuItem.separator())

        appMenu.addItem(withTitle: "Quit \(appName)", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        NSApp.mainMenu = mainMenu
    }

    // MARK: - Global Hotkey

    /// Registers the global hotkey from `AppSettings.globalHotkey`.
    ///
    /// The string is expected in the format `cmd+shift+n`. On activation it
    /// brings the main window to the front (or reopens it if closed).
    private func registerGlobalHotkey() {
        let raw = AppSettings.shared.globalHotkey
        globalHotKey = HotKey(combination: raw)
        globalHotKey?.keyDown = { [weak self] in
            self?.activateMainWindow()
        }
    }

    /// Brings the main window to the front, reopening it if necessary.
    private func activateMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first(where: { $0.title == "NVIDIA LLM" }) {
            window.makeKeyAndOrderFront(self)
        } else {
            NSApp.sendAction(Selector(("showMainWindow:")), to: nil, from: nil)
        }
    }
}
