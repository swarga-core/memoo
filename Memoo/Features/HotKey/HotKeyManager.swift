import AppKit
import HotKey

@MainActor
final class HotKeyManager: ObservableObject {
    static let shared = HotKeyManager()

    @Published private(set) var isEnabled: Bool = true
    @Published var currentKey: Key = .space
    @Published var currentModifiers: NSEvent.ModifierFlags = .option

    private var hotKey: HotKey?

    // UserDefaults keys
    private static let keyCodeKey = "hotKeyCode"
    private static let modifiersKey = "hotKeyModifiers"
    private static let enabledKey = "hotKeyEnabled"

    private init() {
        loadSettings()
        setupHotKey()
    }

    // MARK: - Public API

    func enable() {
        isEnabled = true
        UserDefaults.standard.set(true, forKey: Self.enabledKey)
        setupHotKey()
    }

    func disable() {
        isEnabled = false
        UserDefaults.standard.set(false, forKey: Self.enabledKey)
        hotKey = nil
    }

    func setHotKey(key: Key, modifiers: NSEvent.ModifierFlags) {
        currentKey = key
        currentModifiers = modifiers
        saveSettings()
        if isEnabled {
            setupHotKey()
        }
    }

    func resetToDefault() {
        currentKey = .space
        currentModifiers = .option
        isEnabled = true
        saveSettings()
        setupHotKey()
    }

    // MARK: - Private

    private func loadSettings() {
        // Load enabled state
        if UserDefaults.standard.object(forKey: Self.enabledKey) != nil {
            isEnabled = UserDefaults.standard.bool(forKey: Self.enabledKey)
        }

        // Load key code
        if let keyCodeValue = UserDefaults.standard.object(forKey: Self.keyCodeKey) as? UInt32 {
            if let key = Key(carbonKeyCode: keyCodeValue) {
                currentKey = key
            }
        }

        // Load modifiers
        if let modifiersValue = UserDefaults.standard.object(forKey: Self.modifiersKey) as? UInt {
            currentModifiers = NSEvent.ModifierFlags(rawValue: modifiersValue)
        }
    }

    private func saveSettings() {
        UserDefaults.standard.set(isEnabled, forKey: Self.enabledKey)
        UserDefaults.standard.set(currentKey.carbonKeyCode, forKey: Self.keyCodeKey)
        UserDefaults.standard.set(currentModifiers.rawValue, forKey: Self.modifiersKey)
    }

    private func setupHotKey() {
        hotKey = nil

        guard isEnabled else { return }

        hotKey = HotKey(key: currentKey, modifiers: currentModifiers)
        hotKey?.keyDownHandler = { [weak self] in
            Task { @MainActor in
                self?.handleHotKey()
            }
        }
    }

    private func handleHotKey() {
        WindowManager.shared.toggleWindow()
    }

    // MARK: - For Testing

    #if DEBUG
    func reset() {
        hotKey = nil
        isEnabled = true
        currentKey = .space
        currentModifiers = .option
    }
    #endif
}
