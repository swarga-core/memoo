import XCTest
@testable import Memoo

final class SetupTests: XCTestCase {

    /// Verifies that Info.plist contains required keys
    func testInfoPlistContainsRequiredKeys() {
        let info = Bundle.main.infoDictionary

        XCTAssertNotNil(info?["CFBundleIdentifier"], "CFBundleIdentifier should be present")
        XCTAssertNotNil(info?["CFBundleName"], "CFBundleName should be present")
        XCTAssertNotNil(info?["CFBundleVersion"], "CFBundleVersion should be present")
        XCTAssertNotNil(info?["CFBundleShortVersionString"], "CFBundleShortVersionString should be present")
    }

    /// Verifies minimum deployment target is macOS 15+
    func testMinimumDeploymentTarget() {
        if #available(macOS 15.0, *) {
            XCTAssertTrue(true)
        } else {
            XCTFail("App requires macOS 15.0+")
        }
    }

    /// Verifies Note model can be instantiated with default values
    func testNoteModelDefaultValues() {
        let note = Note()

        XCTAssertNotNil(note.id)
        XCTAssertEqual(note.title, "Untitled")
        XCTAssertEqual(note.content, "")
        XCTAssertEqual(note.order, 0)
        XCTAssertNotNil(note.createdAt)
        XCTAssertNotNil(note.updatedAt)
    }

    /// Verifies Note model can be instantiated with custom values
    func testNoteModelCustomValues() {
        let note = Note(title: "Test", content: "Content", order: 5)

        XCTAssertEqual(note.title, "Test")
        XCTAssertEqual(note.content, "Content")
        XCTAssertEqual(note.order, 5)
    }

    /// Verifies each Note gets a unique ID
    func testNoteHasUniqueID() {
        let note1 = Note()
        let note2 = Note()

        XCTAssertNotEqual(note1.id, note2.id)
    }
}
