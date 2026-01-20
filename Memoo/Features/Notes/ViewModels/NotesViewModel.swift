import SwiftUI
import SwiftData

@Observable
@MainActor
final class NotesViewModel {
    private let modelContext: ModelContext

    private(set) var notes: [Note] = []
    var selectedNoteID: UUID?

    var selectedNote: Note? {
        notes.first { $0.id == selectedNoteID }
    }

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchNotes()
        ensureAtLeastOneNote()
        restoreLastSelectedNote()
    }

    // MARK: - Fetch

    func fetchNotes() {
        let descriptor = FetchDescriptor<Note>(
            sortBy: [SortDescriptor(\.order)]
        )
        notes = (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - Create

    func createNote() {
        let maxOrder = notes.map(\.order).max() ?? -1
        let count = notes.count + 1
        let note = Note(title: "Untitled \(count)", order: maxOrder + 1)
        modelContext.insert(note)
        save()
        fetchNotes()
        selectedNoteID = note.id
        saveLastSelectedNote()
    }

    // MARK: - Delete

    func deleteNote(_ note: Note) {
        let wasSelected = selectedNoteID == note.id
        modelContext.delete(note)
        save()
        fetchNotes()
        ensureAtLeastOneNote()

        if wasSelected {
            selectedNoteID = notes.first?.id
            saveLastSelectedNote()
        }
    }

    // MARK: - Update

    func updateNoteContent(_ note: Note, content: String) {
        note.content = content
        note.updatedAt = Date()
        save()
    }

    func updateNoteTitle(_ note: Note, title: String) {
        note.title = title.isEmpty ? "Untitled" : title
        note.updatedAt = Date()
        save()
    }

    // MARK: - Reorder

    func moveNote(from sourceIndex: Int, to destinationIndex: Int) {
        guard sourceIndex != destinationIndex,
              sourceIndex >= 0, sourceIndex < notes.count,
              destinationIndex >= 0, destinationIndex < notes.count else {
            return
        }

        var mutableNotes = notes
        let movedNote = mutableNotes.remove(at: sourceIndex)
        mutableNotes.insert(movedNote, at: destinationIndex)

        // Update order values
        for (index, note) in mutableNotes.enumerated() {
            note.order = index
        }

        save()
        fetchNotes()
    }

    // MARK: - Duplicate

    func duplicateNote(_ note: Note) {
        let maxOrder = notes.map(\.order).max() ?? -1
        let newNote = Note(
            title: "\(note.title) (Copy)",
            content: note.content,
            order: maxOrder + 1
        )
        modelContext.insert(newNote)
        save()
        fetchNotes()
        selectedNoteID = newNote.id
        saveLastSelectedNote()
    }

    // MARK: - Navigation

    func selectNote(at index: Int) {
        guard index >= 0, index < notes.count else { return }
        selectedNoteID = notes[index].id
        saveLastSelectedNote()
    }

    func selectNextNote() {
        guard !notes.isEmpty else { return }

        if let currentID = selectedNoteID,
           let currentIndex = notes.firstIndex(where: { $0.id == currentID }) {
            let nextIndex = (currentIndex + 1) % notes.count
            selectedNoteID = notes[nextIndex].id
        } else {
            selectedNoteID = notes.first?.id
        }
        saveLastSelectedNote()
    }

    func selectPreviousNote() {
        guard !notes.isEmpty else { return }

        if let currentID = selectedNoteID,
           let currentIndex = notes.firstIndex(where: { $0.id == currentID }) {
            let previousIndex = currentIndex == 0 ? notes.count - 1 : currentIndex - 1
            selectedNoteID = notes[previousIndex].id
        } else {
            selectedNoteID = notes.last?.id
        }
        saveLastSelectedNote()
    }

    // MARK: - Private

    private func ensureAtLeastOneNote() {
        if notes.isEmpty {
            createNote()
        }
        if selectedNoteID == nil {
            selectedNoteID = notes.first?.id
        }
    }

    private func save() {
        try? modelContext.save()
    }

    private func saveLastSelectedNote() {
        if let id = selectedNoteID {
            UserDefaults.standard.set(id.uuidString, forKey: "lastActiveNoteID")
        }
    }

    private func restoreLastSelectedNote() {
        if let idString = UserDefaults.standard.string(forKey: "lastActiveNoteID"),
           let id = UUID(uuidString: idString),
           notes.contains(where: { $0.id == id }) {
            selectedNoteID = id
        }
    }
}
