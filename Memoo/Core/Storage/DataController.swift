import SwiftData
import Foundation

@MainActor
final class DataController {
    static let shared = DataController()

    let container: ModelContainer

    /// On-disk location of the SwiftData store. This matches SwiftData's default
    /// location, so existing data keeps working — we just name it explicitly so
    /// we can back it up before opening.
    static let storeURL = URL.applicationSupportDirectory.appending(path: "default.store")

    private init() {
        let schema = Schema([Note.self])

        // Snapshot the previous session's store BEFORE opening it. If a launch
        // ever empties or rebuilds the store again, the last good copy survives.
        StoreBackup.backup(storeURL: Self.storeURL)

        let config = ModelConfiguration(schema: schema, url: Self.storeURL)

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

/// Best-effort backup of the on-disk store (and its -wal/-shm sidecars), taken
/// before the store is opened. Keeps the most recent `keep` snapshots so a bad
/// launch can never leave the user without a recent copy of their notes.
enum StoreBackup {
    private static let keep = 10
    private static let sidecars = ["", "-wal", "-shm"]

    static func backup(storeURL: URL) {
        let fm = FileManager.default
        guard fm.fileExists(atPath: storeURL.path) else { return }

        let backupsDir = storeURL.deletingLastPathComponent()
            .appending(path: "Backups", directoryHint: .isDirectory)
        do {
            try fm.createDirectory(at: backupsDir, withIntermediateDirectories: true)

            let dest = backupsDir.appending(path: "default-\(timestamp()).store")
            for suffix in sidecars {
                let src = sidecar(storeURL, suffix)
                guard fm.fileExists(atPath: src.path) else { continue }
                let dst = sidecar(dest, suffix)
                try? fm.removeItem(at: dst)
                try fm.copyItem(at: src, to: dst)
            }
            rotate(in: backupsDir, using: fm)
        } catch {
            print("Memoo: store backup failed: \(error)")
        }
    }

    private static func sidecar(_ base: URL, _ suffix: String) -> URL {
        suffix.isEmpty ? base : URL(fileURLWithPath: base.path + suffix)
    }

    private static func timestamp() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter.string(from: Date())
    }

    /// Keeps the newest `keep` snapshots (timestamps sort lexically), deleting
    /// older ones together with their sidecar files.
    private static func rotate(in dir: URL, using fm: FileManager) {
        guard let entries = try? fm.contentsOfDirectory(atPath: dir.path) else { return }
        let snapshots = entries
            .filter { $0.hasPrefix("default-") && $0.hasSuffix(".store") }
            .sorted(by: >) // newest first
        for stale in snapshots.dropFirst(keep) {
            for suffix in sidecars {
                try? fm.removeItem(at: sidecar(dir.appending(path: stale), suffix))
            }
        }
    }
}
