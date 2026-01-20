import XCTest
import SwiftData
@testable import Memoo

final class DataControllerTests: XCTestCase {

    @MainActor
    func testDataController_ForTestingCreatesContainer() {
        let container = DataController.forTesting()
        XCTAssertNotNil(container)
    }

    @MainActor
    func testDataController_ForTestingCreatesInMemoryContainer() {
        let container = DataController.forTesting()
        let context = ModelContext(container)

        // Insert a note
        let note = Note(title: "Test")
        context.insert(note)
        try? context.save()

        // Create a new container - should be empty (in-memory doesn't persist)
        let newContainer = DataController.forTesting()
        let newContext = ModelContext(newContainer)

        let descriptor = FetchDescriptor<Note>()
        let notes = try? newContext.fetch(descriptor)

        XCTAssertEqual(notes?.count ?? 0, 0)
    }

    @MainActor
    func testDataController_ContextCanInsertAndFetch() {
        let container = DataController.forTesting()
        let context = ModelContext(container)

        let note = Note(title: "Context Test")
        context.insert(note)
        try? context.save()

        let descriptor = FetchDescriptor<Note>()
        let notes = try? context.fetch(descriptor)

        XCTAssertEqual(notes?.count, 1)
        XCTAssertEqual(notes?.first?.title, "Context Test")
    }

    @MainActor
    func testDataController_MultipleContextsShareData() {
        let container = DataController.forTesting()

        let context1 = ModelContext(container)
        let note = Note(title: "Shared Note")
        context1.insert(note)
        try? context1.save()

        let context2 = ModelContext(container)
        let descriptor = FetchDescriptor<Note>()
        let notes = try? context2.fetch(descriptor)

        XCTAssertEqual(notes?.count, 1)
    }
}
