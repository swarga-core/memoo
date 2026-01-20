import SwiftUI
import HotKey

struct SettingsView: View {
    @StateObject private var hotKeyManager = HotKeyManager.shared

    var body: some View {
        Form {
            Section("Global Hotkey") {
                HStack {
                    Text("Toggle Window")
                    Spacer()
                    Text(hotKeyDescription)
                        .foregroundStyle(.secondary)
                }

                Toggle("Enable Hotkey", isOn: Binding(
                    get: { hotKeyManager.isEnabled },
                    set: { enabled in
                        if enabled {
                            hotKeyManager.enable()
                        } else {
                            hotKeyManager.disable()
                        }
                    }
                ))

                Button("Reset to Default (⌥ Space)") {
                    hotKeyManager.resetToDefault()
                }
            }

            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(appVersion)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 250)
    }

    private var hotKeyDescription: String {
        var parts: [String] = []

        if hotKeyManager.currentModifiers.contains(.command) {
            parts.append("⌘")
        }
        if hotKeyManager.currentModifiers.contains(.option) {
            parts.append("⌥")
        }
        if hotKeyManager.currentModifiers.contains(.control) {
            parts.append("⌃")
        }
        if hotKeyManager.currentModifiers.contains(.shift) {
            parts.append("⇧")
        }

        let keyName = keyDisplayName(hotKeyManager.currentKey)
        parts.append(keyName)

        return parts.joined(separator: " ")
    }

    private func keyDisplayName(_ key: Key) -> String {
        switch key {
        case .space: return "Space"
        case .a: return "A"
        case .b: return "B"
        case .c: return "C"
        case .d: return "D"
        case .e: return "E"
        case .f: return "F"
        case .g: return "G"
        case .h: return "H"
        case .i: return "I"
        case .j: return "J"
        case .k: return "K"
        case .l: return "L"
        case .m: return "M"
        case .n: return "N"
        case .o: return "O"
        case .p: return "P"
        case .q: return "Q"
        case .r: return "R"
        case .s: return "S"
        case .t: return "T"
        case .u: return "U"
        case .v: return "V"
        case .w: return "W"
        case .x: return "X"
        case .y: return "Y"
        case .z: return "Z"
        default: return "?"
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}

#Preview {
    SettingsView()
}
