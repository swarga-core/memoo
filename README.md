# Memoo

A lightweight, floating note-taking app for macOS designed for developers who need quick access to scratch notes without leaving their workflow.

![macOS](https://img.shields.io/badge/macOS-15.0%2B-blue)
![Swift](https://img.shields.io/badge/Swift-6.0-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## Features

- **Global Hotkey** (⌥+Space) - Instantly show/hide the app from anywhere
- **Floating Window** - Stays on top of other windows, perfect for quick notes
- **Tab-based Interface** - Organize multiple notes with drag-and-drop reordering
- **Auto-save** - Notes are automatically saved as you type
- **Menu Bar Icon** - Quick access from the menu bar
- **No Dock Icon** - Runs as an accessory app, keeping your dock clean
- **Local Storage** - All data stored locally using SwiftData

## Installation

### From Source

1. Clone the repository:
   ```bash
   git clone https://github.com/swarga-core/memoo.git
   cd memoo
   ```

2. Open in Xcode:
   ```bash
   open Memoo/Memoo.xcodeproj
   ```

3. Build and run (⌘+R)

### Requirements

- macOS 15.0 (Tahoe) or later
- Xcode 16.0 or later

## Usage

1. **Launch** - The app starts minimized to the menu bar
2. **Toggle Window** - Press ⌥+Space or click the menu bar icon
3. **Create Tab** - Click the + button in the tab bar
4. **Switch Tabs** - Click on a tab or use ⌘+1-9
5. **Close Tab** - Hover over a tab and click ✕, or right-click → Close
6. **Rename Tab** - Right-click on a tab → Rename
7. **Reorder Tabs** - Drag and drop tabs to rearrange
8. **Hide Window** - Press ⌥+Space or Escape

## Keyboard Shortcuts

| Action | Shortcut |
|--------|----------|
| Toggle Window | ⌥+Space |
| Hide Window | Escape |
| New Note | ⌘+N |
| Close Note | ⌘+W |
| Settings | ⌘+, |
| Quit | ⌘+Q |

## Configuration

Access Settings via the menu bar icon → Settings, or press ⌘+,

- **Global Hotkey** - Customize the hotkey to show/hide the app

## Architecture

Built with modern Apple frameworks:

- **SwiftUI** - Declarative UI
- **SwiftData** - Local persistence
- **HotKey** - Global keyboard shortcuts ([soffes/HotKey](https://github.com/soffes/HotKey))

## License

MIT License - see [LICENSE](LICENSE) for details.
