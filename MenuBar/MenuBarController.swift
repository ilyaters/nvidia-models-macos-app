import SwiftUI
import AppKit

/// Manages the menu bar item and popover.
///
/// Uses `MenuBarExtra` for the status item and renders the popover content
/// via `PopoverView`. The model container is injected by the parent `App`.
struct MenuBarController: Scene {
    var body: some Scene {
        MenuBarExtra {
            PopoverView()
        } label: {
            Image(systemName: "cpu")
                .symbolRenderingMode(.hierarchical)
        }
        .menuBarExtraStyle(.window)
    }
}
