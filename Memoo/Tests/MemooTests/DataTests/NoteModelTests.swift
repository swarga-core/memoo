import XCTest
import SwiftData
@testable import Memoo

final class NoteModelTests: XCTestCase {

    var container: ModelContainer!
    var context: ModelContext!

    @MainActor
    override func setUp() {
        super.setUp()
        container = DataController.forTesting()
        context = ModelContext(container)
    }

    override func tearDown() {
        container = nil
        context = nil
        super.tearDown()
    }

    // MARK: - Creation Tests

    func testNoteCreation_WithDefaults() {
        let note = Note()

        XCTAssertNotNil(note.id)
        XCTAssertEqual(note.title, "Untitled")
        XCTAssertEqual(note.content, "")
        XCTAssertEqual(note.order, 0)
        XCTAssertNotNil(note.createdAt)
        XCTAssertNotNil(note.updatedAt)
    }

    func testNoteCreation_WithCustomValues() {
        let note = Note(title: "Test Note", content: "Hello World", order: 5)

        XCTAssertEqual(note.title, "Test Note")
        XCTAssertEqual(note.content, "Hello World")
        XCTAssertEqual(note.order, 5)
    }

    func testNoteHasUniqueID() {
        let note1 = Note()
        let note2 = Note()

        XCTAssertNotEqual(note1.id, note2.id)
    }

    func testNoteCreatedAtIsSet() {
        let beforeCreation = Date()
        let note = Note()
        let afterCreation = Date()

        XCTAssertGreaterThanOrEqual(note.createdAt, beforeCreation)
        XCTAssertLessThanOrEqual(note.createdAt, afterCreation)
    }

    // MARK: - Persistence Tests

    @MainActor
    func testNotePersistence_Insert() throws {
        let note = Note(title: "Persistent Note", content: "Test Content")
        context.insert(note)
        try context.save()

        let descriptor = FetchDescriptor<Note>()
        let notes = try context.fetch(descriptor)

        XCTAssertEqual(notes.count, 1)
        XCTAssertEqual(notes.first?.title, "Persistent Note")
        XCTAssertEqual(notes.first?.content, "Test Content")
    }

    @MainActor
    func testNotePersistence_Update() throws {
        let note = Note(title: "Original Title")
        context.insert(note)
        try context.save()

        note.title = "Updated Title"
        note.content = "New content"
        note.updatedAt = Date()
        try context.save()

        let descriptor = FetchDescriptor<Note>()
        let notes = try context.fetch(descriptor)

        XCTAssertEqual(notes.first?.title, "Updated Title")
        XCTAssertEqual(notes.first?.content, "New content")
    }

    @MainActor
    func testNotePersistence_Delete() throws {
        let note = Note(title: "To Delete")
        context.insert(note)
        try context.save()

        context.delete(note)
        try context.save()

        let descriptor = FetchDescriptor<Note>()
        let notes = try context.fetch(descriptor)

        XCTAssertEqual(notes.count, 0)
    }

    @MainActor
    func testMultipleNotes_Insert() throws {
        let note1 = Note(title: "Note 1", order: 0)
        let note2 = Note(title: "Note 2", order: 1)
        let note3 = Note(title: "Note 3", order: 2)

        context.insert(note1)
        context.insert(note2)
        context.insert(note3)
        try context.save()

        let descriptor = FetchDescriptor<Note>()
        let notes = try context.fetch(descriptor)

        XCTAssertEqual(notes.count, 3)
    }

    // MARK: - Ordering Tests

    @MainActor
    func testNotesFetchedInOrder() throws {
        let note1 = Note(title: "Third", order: 2)
        let note2 = Note(title: "First", order: 0)
        let note3 = Note(title: "Second", order: 1)

        context.insert(note1)
        context.insert(note2)
        context.insert(note3)
        try context.save()

        var descriptor = FetchDescriptor<Note>(
            sortBy: [SortDescriptor(\.order)]
        )
        let notes = try context.fetch(descriptor)

        XCTAssertEqual(notes[0].title, "First")
        XCTAssertEqual(notes[1].title, "Second")
        XCTAssertEqual(notes[2].title, "Third")
    }

    @MainActor
    func testNotesOrderUpdate() throws {
        let note1 = Note(title: "A", order: 0)
        let note2 = Note(title: "B", order: 1)

        context.insert(note1)
        context.insert(note2)
        try context.save()

        // Swap order
        note1.order = 1
        note2.order = 0
        try context.save()

        var descriptor = FetchDescriptor<Note>(
            sortBy: [SortDescriptor(\.order)]
        )
        let notes = try context.fetch(descriptor)

        XCTAssertEqual(notes[0].title, "B")
        XCTAssertEqual(notes[1].title, "A")
    }

    // MARK: - Content Tests

    @MainActor
    func testNoteWithLargeContent() throws {
        let largeContent = String(repeating: "Lorem ipsum dolor sit amet. ", count: 1000)
        let note = Note(title: "Large Note", content: largeContent)

        context.insert(note)
        try context.save()

        let descriptor = FetchDescriptor<Note>()
        let notes = try context.fetch(descriptor)

        XCTAssertEqual(notes.first?.content.count, largeContent.count)
    }

    @MainActor
    func testNoteWithSpecialCharacters() throws {
        let specialContent = "Emoji 🎉 日本語 العربية <script>alert('xss')</script>"
        let note = Note(title: "Special", content: specialContent)

        context.insert(note)
        try context.save()

        let descriptor = FetchDescriptor<Note>()
        let notes = try context.fetch(descriptor)

        XCTAssertEqual(notes.first?.content, specialContent)
    }
}
