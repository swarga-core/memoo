import AppKit
import SwiftUI
import SwiftData

@MainActor
final class WindowManager: ObservableObject {
    static let shared = WindowManager()

    @Published private(set) var isVisible: Bool = false

    private var panel: FloatingPanel?
    private var modelContainer: ModelContainer?

    private init() {}

    // MARK: - Setup

    func setup(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    // MARK: - Show/Hide

    func showWindow() {
        if panel == nil {
            createPanel()
        }

        guard let panel = panel else { return }

        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        isVisible = true
    }

    func hideWindow() {
        panel?.orderOut(nil)
        isVisible = false
        // Return focus to the previous application
        NSApp.hide(nil)
    }

    func toggleWindow() {
        if isVisible {
            hideWindow()
        } else {
            showWindow()
        }
    }

    // MARK: - Private

    private func createPanel() {
        guard let modelContainer = modelContainer else {
            fatalError("WindowManager.setup(modelContainer:) must be called before showing window")
        }

        let contentView = MainContentView()
            .modelContainer(modelContainer)
            .frame(minWidth: 400, minHeight: 300)

        panel = FloatingPanel(contentView: contentView)
    }

    // MARK: - Window Frame

    func setWindowFrame(_ frame: NSRect) {
        panel?.setFrame(frame, display: true)
    }

    func getSavedWindowFrame() -> NSRect? {
        guard let frameString = UserDefaults.standard.string(forKey: "memooWindowFrame") else {
            return nil
        }
        return NSRectFromString(frameString)
    }

    // MARK: - For Testing

    #if DEBUG
    func reset() {
        panel?.close()
        panel = nil
        isVisible = false
    }
    #endif
}
