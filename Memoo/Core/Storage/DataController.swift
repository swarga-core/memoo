import SwiftData
import Foundation

@MainActor
final class DataController {
    static let shared = DataController()

    let container: ModelContainer

    private init() {
        let schema = Schema([Note.self])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )

        do {
            container = try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    /// In-memory container for testing
    static func forTesting() -> ModelContainer {
        let schema = Schema([Note.self])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        do {
            return try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Failed to create test ModelContainer: \(error)")
        }
    }

    /// Creates a new ModelContext
    var mainContext: ModelContext {
        container.mainContext
    }
}
