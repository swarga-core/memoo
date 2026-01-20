import XCTest
import SwiftData
@testable import Memoo

@MainActor
final class WindowManagerTests: XCTestCase {

    var container: ModelContainer!

    override func setUp() {
        super.setUp()
        container = DataController.forTesting()
        WindowManager.shared.reset()
    }

    override func tearDown() {
        WindowManager.shared.reset()
        container = nil
        UserDefaults.standard.removeObject(forKey: "memooWindowFrame")
        super.tearDown()
    }

    // MARK: - Setup Tests

    func testWindowManager_IsSingleton() {
        let manager1 = WindowManager.shared
        let manager2 = WindowManager.shared
        XCTAssertTrue(manager1 === manager2)
    }

    func testWindowManager_InitiallyNotVisible() {
        XCTAssertFalse(WindowManager.shared.isVisible)
    }

    func testWindowManager_SetupStoresContainer() {
        WindowManager.shared.setup(modelContainer: container)
        // If setup didn't crash, it worked
        XCTAssertFalse(WindowManager.shared.isVisible)
    }

    // MARK: - Show/Hide Tests

    func testWindowManager_ShowWindowSetsVisibleTrue() {
        WindowManager.shared.setup(modelContainer: container)
        WindowManager.shared.showWindow()

        XCTAssertTrue(WindowManager.shared.isVisible)
    }

    func testWindowManager_HideWindowSetsVisibleFalse() {
        WindowManager.shared.setup(modelContainer: container)
        WindowManager.shared.showWindow()
        WindowManager.shared.hideWindow()

        XCTAssertFalse(WindowManager.shared.isVisible)
    }

    func testWindowManager_ToggleFromHiddenShowsWindow() {
        WindowManager.shared.setup(modelContainer: container)
        XCTAssertFalse(WindowManager.shared.isVisible)

        WindowManager.shared.toggleWindow()

        XCTAssertTrue(WindowManager.shared.isVisible)
    }

    func testWindowManager_ToggleFromVisibleHidesWindow() {
        WindowManager.shared.setup(modelContainer: container)
        WindowManager.shared.showWindow()
        XCTAssertTrue(WindowManager.shared.isVisible)

        WindowManager.shared.toggleWindow()

        XCTAssertFalse(WindowManager.shared.isVisible)
    }

    func testWindowManager_MultipleShowCallsRemainVisible() {
        WindowManager.shared.setup(modelContainer: container)
        WindowManager.shared.showWindow()
        WindowManager.shared.showWindow()
        WindowManager.shared.showWindow()

        XCTAssertTrue(WindowManager.shared.isVisible)
    }

    func testWindowManager_MultipleHideCallsRemainHidden() {
        WindowManager.shared.setup(modelContainer: container)
        WindowManager.shared.showWindow()
        WindowManager.shared.hideWindow()
        WindowManager.shared.hideWindow()
        WindowManager.shared.hideWindow()

        XCTAssertFalse(WindowManager.shared.isVisible)
    }

    // MARK: - Frame Persistence Tests

    func testWindowManager_GetSavedWindowFrameReturnsNilWhenNotSet() {
        UserDefaults.standard.removeObject(forKey: "memooWindowFrame")

        let frame = WindowManager.shared.getSavedWindowFrame()

        XCTAssertNil(frame)
    }

    func testWindowManager_ResetClearsState() {
        WindowManager.shared.setup(modelContainer: container)
        WindowManager.shared.showWindow()
        XCTAssertTrue(WindowManager.shared.isVisible)

        WindowManager.shared.reset()

        XCTAssertFalse(WindowManager.shared.isVisible)
    }
}
