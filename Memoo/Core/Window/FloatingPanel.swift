import AppKit
import SwiftUI

final class FloatingPanel: NSPanel {

    private var localEventMonitor: Any?

    init<Content: View>(contentView: Content) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
            styleMask: [.titled, .closable, .resizable, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        // Panel configuration
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.isMovableByWindowBackground = true
        self.titlebarAppearsTransparent = true
        self.titleVisibility = .hidden
        self.backgroundColor = .windowBackgroundColor

        // Hide standard window buttons
        self.standardWindowButton(.closeButton)?.isHidden = true
        self.standardWindowButton(.miniaturizeButton)?.isHidden = true
        self.standardWindowButton(.zoomButton)?.isHidden = true

        // Set minimum size
        self.minSize = NSSize(width: 400, height: 300)

        // Set SwiftUI content
        self.contentView = NSHostingView(rootView: contentView)

        // Restore saved frame or center on screen
        if let savedFrame = getSavedFrame() {
            self.setFrame(savedFrame, display: true)
        } else {
            self.center()
        }

        // Save frame on move/resize
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidMove),
            name: NSWindow.didMoveNotification,
            object: self
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidResize),
            name: NSWindow.didResizeNotification,
            object: self
        )

        // Local event monitor to intercept Tab before TextEditor
        setupTabMonitor()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        if let monitor = localEventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    private func setupTabMonitor() {
        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self, event.window == self else { return event }

            // Tab key (keyCode 48)
            if event.keyCode == 48 {
                if event.modifierFlags.contains(.shift) {
                    NotificationCenter.default.post(name: .selectPreviousTab, object: nil)
                } else {
                    NotificationCenter.default.post(name: .selectNextTab, object: nil)
                }
                return nil // Consume the event
            }
            return event
        }
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    // MARK: - Escape key handling

    override func cancelOperation(_ sender: Any?) {
        // Escape hides the window
        WindowManager.shared.hideWindow()
    }

    // MARK: - Frame persistence

    private static let frameKey = "memooWindowFrame"

    @objc private func windowDidMove(_ notification: Notification) {
        saveFrame()
    }

    @objc private func windowDidResize(_ notification: Notification) {
        saveFrame()
    }

    private func saveFrame() {
        let frameString = NSStringFromRect(self.frame)
        UserDefaults.standard.set(frameString, forKey: Self.frameKey)
    }

    private func getSavedFrame() -> NSRect? {
        guard let frameString = UserDefaults.standard.string(forKey: Self.frameKey) else {
            return nil
        }
        let frame = NSRectFromString(frameString)
        // Validate frame is on screen
        guard frame.width > 0, frame.height > 0 else {
            return nil
        }
        // Check if frame is visible on any screen
        let isOnScreen = NSScreen.screens.contains { screen in
            screen.visibleFrame.intersects(frame)
        }
        return isOnScreen ? frame : nil
    }
}
