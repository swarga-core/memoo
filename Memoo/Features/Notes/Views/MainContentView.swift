import SwiftUI
import SwiftData
import AppKit

struct MainContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: NotesViewModel?

    var body: some View {
        Group {
            if let viewModel = viewModel {
                if viewModel.loadFailed {
                    StoreErrorView()
                } else {
                    MainContentInnerView(viewModel: viewModel)
                        .handleCommands()
                }
            } else {
                ProgressView()
                    .onAppear {
                        viewModel = NotesViewModel(modelContext: modelContext)
                    }
            }
        }
    }
}

/// Shown when the notes store can't be read. We intentionally do NOT create or
/// save anything here — the on-disk data is left untouched so it stays
/// recoverable, and the user is told what happened instead of seeing an empty
/// app that quietly overwrites their notes.
struct StoreErrorView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 32))
                .foregroundStyle(.orange)
            Text("Couldn't open your notes")
                .font(.headline)
            Text("The notes database couldn't be read. Your data has not been modified and a backup is kept at\nApplication Support → Backups.\n\nPlease quit and restart. If notes are still missing, the backup can be restored.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Button("Quit Memoo") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }
        .padding(24)
        .frame(minWidth: 400, minHeight: 300)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

struct MainContentInnerView: View {
    @Bindable var viewModel: NotesViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Tab bar
            TabBarView(viewModel: viewModel)

            Divider()

            // Editor
            NoteEditorWrapper(
                note: viewModel.selectedNote,
                onContentChange: { note, content in
                    viewModel.updateNoteContent(note, content: content)
                }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 400, minHeight: 300)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

// MARK: - App Commands for keyboard shortcuts

struct NotesCommands: Commands {
    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button("New Tab") {
                NotificationCenter.default.post(name: .createNewTab, object: nil)
            }
            .keyboardShortcut("t", modifiers: .command)

            Button("Close Tab") {
                NotificationCenter.default.post(name: .closeCurrentTab, object: nil)
            }
            .keyboardShortcut("w", modifiers: .command)

            Divider()

            Button("Next Tab") {
                NotificationCenter.default.post(name: .selectNextTab, object: nil)
            }
            .keyboardShortcut("]", modifiers: .command)

            Button("Previous Tab") {
                NotificationCenter.default.post(name: .selectPreviousTab, object: nil)
            }
            .keyboardShortcut("[", modifiers: .command)

            Divider()

            Button("Tab 1") {
                NotificationCenter.default.post(name: .selectTabAtIndex, object: 0)
            }
            .keyboardShortcut("1", modifiers: .command)

            Button("Tab 2") {
                NotificationCenter.default.post(name: .selectTabAtIndex, object: 1)
            }
            .keyboardShortcut("2", modifiers: .command)

            Button("Tab 3") {
                NotificationCenter.default.post(name: .selectTabAtIndex, object: 2)
            }
            .keyboardShortcut("3", modifiers: .command)

            Button("Tab 4") {
                NotificationCenter.default.post(name: .selectTabAtIndex, object: 3)
            }
            .keyboardShortcut("4", modifiers: .command)

            Button("Tab 5") {
                NotificationCenter.default.post(name: .selectTabAtIndex, object: 4)
            }
            .keyboardShortcut("5", modifiers: .command)
        }
    }
}

// MARK: - View Extension for handling commands

extension MainContentInnerView {
    func handleCommands() -> some View {
        self
            .onReceive(NotificationCenter.default.publisher(for: .createNewTab)) { _ in
                viewModel.createNote()
            }
            .onReceive(NotificationCenter.default.publisher(for: .closeCurrentTab)) { _ in
                if let note = viewModel.selectedNote {
                    viewModel.deleteNote(note)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .selectNextTab)) { _ in
                viewModel.selectNextNote()
            }
            .onReceive(NotificationCenter.default.publisher(for: .selectPreviousTab)) { _ in
                viewModel.selectPreviousNote()
            }
            .onReceive(NotificationCenter.default.publisher(for: .selectTabAtIndex)) { notification in
                if let index = notification.object as? Int {
                    viewModel.selectNote(at: index)
                }
            }
    }
}

// Preview removed - requires async @MainActor context
