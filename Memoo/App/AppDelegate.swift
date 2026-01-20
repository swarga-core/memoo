import AppKit
import SwiftUI
import SwiftData

final class AppDelegate: NSObject, NSApplicationDelegate {

    var modelContainer: ModelContainer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Configure app behavior - accessory mode hides from dock
        NSApp.setActivationPolicy(.accessory)

        // Setup WindowManager with model container
        if let container = modelContainer {
            WindowManager.shared.setup(modelContainer: container)
        }

        // Setup global hotkey
        setupHotKey()

        // Setup menu bar icon
        setupStatusBar()
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Cleanup if needed
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // Show main window when clicking dock icon (if visible)
        if !flag {
            WindowManager.shared.showWindow()
        }
        return true
    }

    @MainActor private func setupHotKey() {
        // Initialize HotKeyManager - it auto-registers the hotkey
        _ = HotKeyManager.shared
    }

    @MainActor private func setupStatusBar() {
        StatusBarController.shared.setup()
    }
}
