import SwiftUI
import SwiftData
import AppKit

struct MainContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: NotesViewModel?

    var body: some View {
        Group {
            if let viewModel = viewModel {
                MainContentInnerView(viewModel: viewModel)
                    .handleCommands()
            } else {
                ProgressView()
                    .onAppear {
                        viewModel = NotesViewModel(modelContext: modelContext)
                    }
            }
        }
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
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let createNewTab = Notification.Name("createNewTab")
    static let closeCurrentTab = Notification.Name("closeCurrentTab")
    static let selectNextTab = Notification.Name("selectNextTab")
    static let selectPreviousTab = Notification.Name("selectPreviousTab")
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
    }
}

// Preview removed - requires async @MainActor context
