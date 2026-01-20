import XCTest
import HotKey
@testable import Memoo

@MainActor
final class HotKeyManagerTests: XCTestCase {

    override func setUp() {
        super.setUp()
        HotKeyManager.shared.reset()
        // Clear UserDefaults for test isolation
        UserDefaults.standard.removeObject(forKey: "hotKeyCode")
        UserDefaults.standard.removeObject(forKey: "hotKeyModifiers")
        UserDefaults.standard.removeObject(forKey: "hotKeyEnabled")
    }

    override func tearDown() {
        HotKeyManager.shared.reset()
        UserDefaults.standard.removeObject(forKey: "hotKeyCode")
        UserDefaults.standard.removeObject(forKey: "hotKeyModifiers")
        UserDefaults.standard.removeObject(forKey: "hotKeyEnabled")
        super.tearDown()
    }

    // MARK: - Singleton Tests

    func testHotKeyManager_IsSingleton() {
        let manager1 = HotKeyManager.shared
        let manager2 = HotKeyManager.shared
        XCTAssertTrue(manager1 === manager2)
    }

    // MARK: - Default Values Tests

    func testHotKeyManager_DefaultKeyIsSpace() {
        XCTAssertEqual(HotKeyManager.shared.currentKey, .space)
    }

    func testHotKeyManager_DefaultModifiersIsOption() {
        XCTAssertEqual(HotKeyManager.shared.currentModifiers, .option)
    }

    func testHotKeyManager_DefaultIsEnabled() {
        XCTAssertTrue(HotKeyManager.shared.isEnabled)
    }

    // MARK: - Enable/Disable Tests

    func testHotKeyManager_DisableSetsEnabledFalse() {
        HotKeyManager.shared.disable()
        XCTAssertFalse(HotKeyManager.shared.isEnabled)
    }

    func testHotKeyManager_EnableSetsEnabledTrue() {
        HotKeyManager.shared.disable()
        HotKeyManager.shared.enable()
        XCTAssertTrue(HotKeyManager.shared.isEnabled)
    }

    func testHotKeyManager_DisablePersistsToUserDefaults() {
        HotKeyManager.shared.disable()
        XCTAssertFalse(UserDefaults.standard.bool(forKey: "hotKeyEnabled"))
    }

    func testHotKeyManager_EnablePersistsToUserDefaults() {
        HotKeyManager.shared.disable()
        HotKeyManager.shared.enable()
        XCTAssertTrue(UserDefaults.standard.bool(forKey: "hotKeyEnabled"))
    }

    // MARK: - Set HotKey Tests

    func testHotKeyManager_SetHotKeyUpdatesKey() {
        HotKeyManager.shared.setHotKey(key: .a, modifiers: .command)

        XCTAssertEqual(HotKeyManager.shared.currentKey, .a)
        XCTAssertEqual(HotKeyManager.shared.currentModifiers, .command)
    }

    func testHotKeyManager_SetHotKeyPersistsToUserDefaults() {
        HotKeyManager.shared.setHotKey(key: .b, modifiers: .control)

        // Check key code was saved
        let savedKeyCode = UserDefaults.standard.object(forKey: "hotKeyCode") as? UInt32
        XCTAssertNotNil(savedKeyCode)
        XCTAssertEqual(savedKeyCode, Key.b.carbonKeyCode)

        // Check modifiers were saved
        let savedModifiers = UserDefaults.standard.object(forKey: "hotKeyModifiers") as? UInt
        XCTAssertNotNil(savedModifiers)
        XCTAssertEqual(savedModifiers, NSEvent.ModifierFlags.control.rawValue)
    }

    // MARK: - Reset Tests

    func testHotKeyManager_ResetRestoresDefaults() {
        HotKeyManager.shared.setHotKey(key: .a, modifiers: .command)
        HotKeyManager.shared.disable()

        HotKeyManager.shared.resetToDefault()

        XCTAssertEqual(HotKeyManager.shared.currentKey, .space)
        XCTAssertEqual(HotKeyManager.shared.currentModifiers, .option)
        XCTAssertTrue(HotKeyManager.shared.isEnabled)
    }

    // MARK: - Multiple Modifier Tests

    func testHotKeyManager_SupportsMultipleModifiers() {
        let modifiers: NSEvent.ModifierFlags = [.command, .shift]
        HotKeyManager.shared.setHotKey(key: .n, modifiers: modifiers)

        XCTAssertEqual(HotKeyManager.shared.currentKey, .n)
        XCTAssertTrue(HotKeyManager.shared.currentModifiers.contains(.command))
        XCTAssertTrue(HotKeyManager.shared.currentModifiers.contains(.shift))
    }
}
