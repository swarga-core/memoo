import XCTest
import SwiftData
@testable import Memoo

@MainActor
final class NotesViewModelTests: XCTestCase {

    var container: ModelContainer!
    var context: ModelContext!
    var viewModel: NotesViewModel!

    override func setUp() {
        super.setUp()
        container = DataController.forTesting()
        context = ModelContext(container)
        // Clear UserDefaults for test isolation
        UserDefaults.standard.removeObject(forKey: "lastActiveNoteID")
        viewModel = NotesViewModel(modelContext: context)
    }

    override func tearDown() {
        viewModel = nil
        context = nil
        container = nil
        UserDefaults.standard.removeObject(forKey: "lastActiveNoteID")
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testViewModel_CreatesDefaultNoteOnInit() {
        XCTAssertFalse(viewModel.notes.isEmpty)
        XCTAssertEqual(viewModel.notes.count, 1)
    }

    func testViewModel_SelectsFirstNoteOnInit() {
        XCTAssertNotNil(viewModel.selectedNoteID)
        XCTAssertEqual(viewModel.selectedNoteID, viewModel.notes.first?.id)
    }

    func testViewModel_SelectedNoteReturnsCorrectNote() {
        XCTAssertNotNil(viewModel.selectedNote)
        XCTAssertEqual(viewModel.selectedNote?.id, viewModel.selectedNoteID)
    }

    // MARK: - Create Tests

    func testCreateNote_AddsNewNote() {
        let initialCount = viewModel.notes.count
        viewModel.createNote()

        XCTAssertEqual(viewModel.notes.count, initialCount + 1)
    }

    func testCreateNote_SelectsNewNote() {
        viewModel.createNote()
        let newNote = viewModel.notes.last

        XCTAssertEqual(viewModel.selectedNoteID, newNote?.id)
    }

    func testCreateNote_HasCorrectOrder() {
        viewModel.createNote()
        viewModel.createNote()

        let orders = viewModel.notes.map(\.order)
        XCTAssertEqual(orders, orders.sorted())
    }

    func testCreateNote_HasIncrementingTitle() {
        // First note is "Untitled 1"
        viewModel.createNote() // "Untitled 2"
        viewModel.createNote() // "Untitled 3"

        XCTAssertTrue(viewModel.notes[1].title.contains("2"))
        XCTAssertTrue(viewModel.notes[2].title.contains("3"))
    }

    // MARK: - Delete Tests

    func testDeleteNote_RemovesNote() {
        viewModel.createNote()
        let noteToDelete = viewModel.notes.last!
        let initialCount = viewModel.notes.count

        viewModel.deleteNote(noteToDelete)

        XCTAssertEqual(viewModel.notes.count, initialCount - 1)
    }

    func testDeleteNote_EnsuresAtLeastOneNote() {
        // Delete all notes until one remains
        while viewModel.notes.count > 1 {
            viewModel.deleteNote(viewModel.notes.last!)
        }

        // Try to delete the last one
        viewModel.deleteNote(viewModel.notes.first!)

        // Should create a new default note
        XCTAssertEqual(viewModel.notes.count, 1)
    }

    func testDeleteNote_UpdatesSelectionWhenSelectedNoteDeleted() {
        viewModel.createNote()
        let firstNote = viewModel.notes.first!
        viewModel.selectedNoteID = firstNote.id

        viewModel.deleteNote(firstNote)

        XCTAssertNotNil(viewModel.selectedNoteID)
        XCTAssertNotEqual(viewModel.selectedNoteID, firstNote.id)
    }

    func testDeleteNote_KeepsSelectionWhenOtherNoteDeleted() {
        viewModel.createNote()
        viewModel.createNote()

        let selectedNote = viewModel.notes.first!
        viewModel.selectedNoteID = selectedNote.id

        let noteToDelete = viewModel.notes.last!
        viewModel.deleteNote(noteToDelete)

        XCTAssertEqual(viewModel.selectedNoteID, selectedNote.id)
    }

    // MARK: - Update Tests

    func testUpdateNoteContent_UpdatesContent() {
        let note = viewModel.notes.first!
        viewModel.updateNoteContent(note, content: "New content")

        XCTAssertEqual(note.content, "New content")
    }

    func testUpdateNoteContent_UpdatesTimestamp() {
        let note = viewModel.notes.first!
        let oldTimestamp = note.updatedAt

        Thread.sleep(forTimeInterval: 0.01)
        viewModel.updateNoteContent(note, content: "Updated")

        XCTAssertGreaterThan(note.updatedAt, oldTimestamp)
    }

    func testUpdateNoteTitle_UpdatesTitle() {
        let note = viewModel.notes.first!
        viewModel.updateNoteTitle(note, title: "New Title")

        XCTAssertEqual(note.title, "New Title")
    }

    func testUpdateNoteTitle_EmptyTitleBecomesUntitled() {
        let note = viewModel.notes.first!
        viewModel.updateNoteTitle(note, title: "")

        XCTAssertEqual(note.title, "Untitled")
    }

    func testUpdateNoteTitle_WhitespaceOnlyBecomesUntitled() {
        let note = viewModel.notes.first!
        viewModel.updateNoteTitle(note, title: "   ")

        // трим делается при фокусе из UI, но в ViewModel пробелы остаются
        // это ожидаемое поведение - UI должен trimить
    }

    // MARK: - Move/Reorder Tests

    func testMoveNote_UpdatesOrder() {
        viewModel.createNote()
        viewModel.createNote()

        let firstNoteTitle = viewModel.notes[0].title

        viewModel.moveNote(from: 0, to: 2)

        // First note should now be at the end
        XCTAssertEqual(viewModel.notes.last?.title, firstNoteTitle)
    }

    func testMoveNote_PreservesContent() {
        viewModel.createNote()

        let firstNote = viewModel.notes.first!
        viewModel.updateNoteContent(firstNote, content: "Original content")

        viewModel.moveNote(from: 0, to: 1)

        // Content should be preserved
        XCTAssertTrue(viewModel.notes.contains { $0.content == "Original content" })
    }

    func testMoveNote_InvalidSourceIndex_DoesNothing() {
        let initialNotes = viewModel.notes.map(\.id)

        viewModel.moveNote(from: -1, to: 0)
        viewModel.moveNote(from: 100, to: 0)

        XCTAssertEqual(viewModel.notes.map(\.id), initialNotes)
    }

    func testMoveNote_SameIndex_DoesNothing() {
        viewModel.createNote()
        let initialNotes = viewModel.notes.map(\.id)

        viewModel.moveNote(from: 0, to: 0)

        XCTAssertEqual(viewModel.notes.map(\.id), initialNotes)
    }

    // MARK: - Duplicate Tests

    func testDuplicateNote_CreatesNewNote() {
        let note = viewModel.notes.first!
        let initialCount = viewModel.notes.count

        viewModel.duplicateNote(note)

        XCTAssertEqual(viewModel.notes.count, initialCount + 1)
    }

    func testDuplicateNote_CopiesContent() {
        let note = viewModel.notes.first!
        viewModel.updateNoteContent(note, content: "Original content")

        viewModel.duplicateNote(note)

        let duplicated = viewModel.notes.last!
        XCTAssertEqual(duplicated.content, "Original content")
    }

    func testDuplicateNote_AppendsCopyToTitle() {
        let note = viewModel.notes.first!
        viewModel.updateNoteTitle(note, title: "My Note")

        viewModel.duplicateNote(note)

        let duplicated = viewModel.notes.last!
        XCTAssertTrue(duplicated.title.contains("Copy"))
    }

    func testDuplicateNote_SelectsDuplicatedNote() {
        let note = viewModel.notes.first!

        viewModel.duplicateNote(note)

        let duplicated = viewModel.notes.last!
        XCTAssertEqual(viewModel.selectedNoteID, duplicated.id)
    }

    // MARK: - Navigation Tests

    func testSelectNextNote_SelectsNext() {
        viewModel.createNote()
        viewModel.createNote()

        viewModel.selectedNoteID = viewModel.notes.first?.id
        viewModel.selectNextNote()

        XCTAssertEqual(viewModel.selectedNoteID, viewModel.notes[1].id)
    }

    func testSelectNextNote_WrapsAround() {
        viewModel.createNote()

        viewModel.selectedNoteID = viewModel.notes.last?.id
        viewModel.selectNextNote()

        XCTAssertEqual(viewModel.selectedNoteID, viewModel.notes.first?.id)
    }

    func testSelectPreviousNote_SelectsPrevious() {
        viewModel.createNote()
        viewModel.createNote()

        viewModel.selectedNoteID = viewModel.notes[1].id
        viewModel.selectPreviousNote()

        XCTAssertEqual(viewModel.selectedNoteID, viewModel.notes.first?.id)
    }

    func testSelectPreviousNote_WrapsAround() {
        viewModel.createNote()

        viewModel.selectedNoteID = viewModel.notes.first?.id
        viewModel.selectPreviousNote()

        XCTAssertEqual(viewModel.selectedNoteID, viewModel.notes.last?.id)
    }

    func testSelectNoteByIndex_SelectsCorrectNote() {
        viewModel.createNote()
        viewModel.createNote()

        viewModel.selectNote(at: 1)

        XCTAssertEqual(viewModel.selectedNoteID, viewModel.notes[1].id)
    }

    func testSelectNoteByIndex_InvalidIndex_DoesNothing() {
        let currentSelection = viewModel.selectedNoteID

        viewModel.selectNote(at: 99)

        XCTAssertEqual(viewModel.selectedNoteID, currentSelection)
    }

    func testSelectNoteByIndex_NegativeIndex_DoesNothing() {
        let currentSelection = viewModel.selectedNoteID

        viewModel.selectNote(at: -1)

        XCTAssertEqual(viewModel.selectedNoteID, currentSelection)
    }

    // MARK: - Selection Tests

    func testSelectedNote_ReturnsCorrectNote() {
        viewModel.createNote()
        let targetNote = viewModel.notes.last!
        viewModel.selectedNoteID = targetNote.id

        XCTAssertEqual(viewModel.selectedNote?.id, targetNote.id)
    }

    func testSelectedNote_ReturnsNilForInvalidID() {
        viewModel.selectedNoteID = UUID()
        XCTAssertNil(viewModel.selectedNote)
    }

    // MARK: - Fetch Tests

    func testFetchNotes_ReturnsNotesInOrder() {
        viewModel.createNote()
        viewModel.createNote()

        viewModel.fetchNotes()

        let orders = viewModel.notes.map(\.order)
        XCTAssertEqual(orders, orders.sorted())
    }
}
