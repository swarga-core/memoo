import SwiftUI

@Observable
@MainActor
final class EditorSettings {
    static let shared = EditorSettings()

    private let defaults = UserDefaults.standard

    var fontFamily: String {
        didSet { defaults.set(fontFamily, forKey: "editorFontFamily") }
    }

    var fontSize: CGFloat {
        didSet { defaults.set(fontSize, forKey: "editorFontSize") }
    }

    var font: Font {
        if fontFamily == "System" {
            return .system(size: fontSize)
        } else if fontFamily == "System Mono" {
            return .system(size: fontSize, design: .monospaced)
        } else {
            return .custom(fontFamily, size: fontSize)
        }
    }

    var nsFont: NSFont {
        if fontFamily == "System" {
            return NSFont.systemFont(ofSize: fontSize)
        } else if fontFamily == "System Mono" {
            return NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        } else {
            return NSFont(name: fontFamily, size: fontSize) ?? NSFont.systemFont(ofSize: fontSize)
        }
    }

    static let availableFonts: [String] = [
        "System",
        "System Mono",
        "Menlo",
        "Monaco",
        "SF Mono",
        "Courier New"
    ]

    private init() {
        self.fontFamily = defaults.string(forKey: "editorFontFamily") ?? "System"
        self.fontSize = defaults.object(forKey: "editorFontSize") as? CGFloat ?? 14
    }
}
