import AppKit
import SwiftUI

@MainActor
final class StatusBarController {
    private var statusItem: NSStatusItem?
    private var menu: NSMenu?

    static let shared = StatusBarController()

    private init() {}

    func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            // Use custom app icon for menu bar
            if let icon = NSImage(named: "AppIcon") {
                icon.size = NSSize(width: 18, height: 18)
                icon.isTemplate = false
                button.image = icon
            } else {
                // Fallback to system symbol
                button.image = NSImage(systemSymbolName: "note.text", accessibilityDescription: "Memoo")
            }
            button.action = #selector(statusBarButtonClicked(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        setupMenu()
    }

    private func setupMenu() {
        menu = NSMenu()

        let showItem = NSMenuItem(title: "Show Memoo", action: #selector(showWindow), keyEquivalent: "")
        showItem.target = self
        menu?.addItem(showItem)

        menu?.addItem(NSMenuItem.separator())

        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu?.addItem(settingsItem)

        menu?.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit Memoo", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu?.addItem(quitItem)
    }

    @objc private func statusBarButtonClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseUp {
            // Right click - show menu
            statusItem?.menu = menu
            statusItem?.button?.performClick(nil)
            // Reset menu to nil so left click works next time
            DispatchQueue.main.async { [weak self] in
                self?.statusItem?.menu = nil
            }
        } else {
            // Left click - toggle window
            WindowManager.shared.toggleWindow()
        }
    }

    @objc private func showWindow() {
        WindowManager.shared.showWindow()
    }

    @objc private func openSettings() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
