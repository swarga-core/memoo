import SwiftUI
import AppKit

struct NoteEditorView: View {
    @Binding var content: String
    let onContentChange: (String) -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        TextEditor(text: $content)
            .font(.system(.body, design: .monospaced))
            .scrollContentBackground(.hidden)
            .background(Color(nsColor: .textBackgroundColor))
            .focused($isFocused)
            .onChange(of: content) { _, newValue in
                onContentChange(newValue)
            }
            .onAppear {
                // Focus the editor when it appears
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isFocused = true
                }
            }
            .accessibilityIdentifier("NoteEditor")
            .accessibilityLabel("Note content editor")
    }
}

struct NoteEditorWrapper: View {
    let note: Note?
    let onContentChange: (Note, String) -> Void

    @State private var localContent: String = ""

    var body: some View {
        Group {
            if let note = note {
                NoteEditorView(
                    content: $localContent,
                    onContentChange: { newContent in
                        onContentChange(note, newContent)
                    }
                )
                .onChange(of: note.id) { _, _ in
                    localContent = note.content
                }
                .onAppear {
                    localContent = note.content
                }
            } else {
                Text("No note selected")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

#Preview {
    @Previewable @State var content = "Hello, World!\n\nThis is a test note with some content."

    NoteEditorView(content: $content, onContentChange: { _ in })
        .frame(width: 500, height: 300)
}
