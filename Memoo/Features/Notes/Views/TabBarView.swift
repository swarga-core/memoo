import SwiftUI
import SwiftData

struct TabBarView: View {
    @Bindable var viewModel: NotesViewModel

    var body: some View {
        HStack(spacing: 2) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 2) {
                    ForEach(Array(viewModel.notes.enumerated()), id: \.element.id) { index, note in
                        TabItemView(
                            note: note,
                            index: index,
                            isSelected: viewModel.selectedNoteID == note.id,
                            onSelect: {
                                viewModel.selectedNoteID = note.id
                            },
                            onClose: {
                                viewModel.deleteNote(note)
                            },
                            onRename: { newTitle in
                                viewModel.updateNoteTitle(note, title: newTitle)
                            },
                            onDuplicate: {
                                viewModel.duplicateNote(note)
                            }
                        )
                        .draggable(note.id.uuidString) {
                            Text(note.title)
                                .padding(8)
                                .background(Color.accentColor.opacity(0.2))
                                .cornerRadius(6)
                        }
                        .dropDestination(for: String.self) { items, _ in
                            guard let draggedIDString = items.first,
                                  let draggedID = UUID(uuidString: draggedIDString),
                                  let fromIndex = viewModel.notes.firstIndex(where: { $0.id == draggedID }),
                                  let toIndex = viewModel.notes.firstIndex(where: { $0.id == note.id }) else {
                                return false
                            }
                            viewModel.moveNote(from: fromIndex, to: toIndex)
                            return true
                        }
                    }
                }
                .padding(.horizontal, 4)
            }

            Divider()
                .frame(height: 20)

            Button(action: {
                viewModel.createNote()
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 8)
            .accessibilityIdentifier("AddTabButton")
            .accessibilityLabel("Add new tab")
        }
        .padding(.vertical, 6)
        .background(Color(nsColor: .controlBackgroundColor))
        .accessibilityIdentifier("TabBar")
    }
}

// Preview removed - requires @MainActor context
