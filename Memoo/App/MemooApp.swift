import SwiftUI
import SwiftData

@main
struct MemooApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    static let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Note.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    init() {
        // Pass model container to AppDelegate immediately
        appDelegate.modelContainer = Self.sharedModelContainer
    }

    var body: some Scene {
        // No main window - app uses FloatingPanel via WindowManager
        // Triggered by global hotkey (⌥+Space) or menu bar icon

        Settings {
            SettingsView()
        }
        .commands {
            NotesCommands()
        }
    }
}
