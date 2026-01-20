# Memoo - Development Guidelines

## About This Project

Memoo is a lightweight floating note-taking app for macOS (15.0+). Uses SwiftUI, SwiftData, and HotKey library.

## Development Principles

### Keep It Simple
- This is a lightweight app — avoid over-engineering
- No unnecessary abstractions or "future-proofing"
- Prefer direct solutions over clever ones

### Code Style
- Use `@MainActor` for all UI-related classes
- Use `@Observable` macro (not ObservableObject) for ViewModels
- Singletons: `static let shared` + `private init()`
- Keep files small and focused — one responsibility per file

### SwiftUI Preferences
- Prefer native SwiftUI views when possible
- Use AppKit (NSPanel, NSStatusItem) only where SwiftUI lacks functionality
- No UIKit — this is macOS only

## Important Constraints

### Window Architecture
- App uses custom `FloatingPanel` (NSPanel), NOT SwiftUI WindowGroup
- `MemooApp.swift` contains only `Settings` scene — no WindowGroup
- Adding WindowGroup will create duplicate windows

### Focus Behavior
- When hiding window, MUST call `NSApp.hide(nil)` to return focus to previous app
- Without this, focus stays on Memoo (invisible) and user loses keyboard input

### Tab Interactions
- Single tap to select — never use double-tap gestures (causes ~1 second delay)
- Rename functionality via context menu only

### App Mode
- Runs as accessory app (LSUIElement=true) — no dock icon
- Menu bar icon is the primary access point

## Build & Test

```bash
# Build
xcodebuild -project Memoo/Memoo.xcodeproj -scheme Memoo -configuration Release build

# Test
xcodebuild -project Memoo/Memoo.xcodeproj -scheme Memoo test

# Install
cp -R ~/Library/Developer/Xcode/DerivedData/Memoo-*/Build/Products/Release/Memoo.app /Applications/
```

## What NOT To Do

1. Don't add WindowGroup to MemooApp — use FloatingPanel via WindowManager
2. Don't use double-tap gestures — they conflict with single tap and cause delays
3. Don't forget `NSApp.hide(nil)` in hideWindow — breaks focus return
4. Don't remove `@MainActor` from UI classes — causes threading issues
5. Don't use Preview macros if they fail with @MainActor — just remove them

## File Structure

```
Memoo/
├── App/           # Entry point, AppDelegate
├── Core/          # Window, MenuBar, Data management
├── Features/      # Notes, Settings, HotKey
└── Resources/     # Assets, icons
```

## Dependencies

- [HotKey](https://github.com/soffes/HotKey) — global keyboard shortcuts (via SPM)

## Git & Releases

- **Commits**: AI suggests commits but only executes with explicit user approval
- **CHANGELOG**: Update only when releasing a new version
- **Version bump**: Only for user-visible changes; tag with `git tag v1.x.x`
