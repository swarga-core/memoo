import SwiftUI

struct TabItemView: View {
    let note: Note
    let index: Int?
    let isSelected: Bool
    let onSelect: () -> Void
    let onClose: () -> Void
    let onRename: (String) -> Void
    let onDuplicate: () -> Void

    private var displayTitle: String {
        if let index = index, index < 5 {
            return "\(index + 1): \(note.title)"
        }
        return note.title
    }

    @State private var isEditing = false
    @State private var editedTitle = ""

    var body: some View {
        HStack(spacing: 4) {
            if isEditing {
                TextField("", text: $editedTitle, onCommit: commitRename)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .frame(minWidth: 60)
                    .onAppear {
                        editedTitle = note.title
                    }
            } else {
                Text(displayTitle)
                    .font(.system(size: 12))
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isSelected ? Color.accentColor.opacity(0.5) : Color.clear, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
        .contextMenu {
            Button("Rename") {
                isEditing = true
            }
            Button("Duplicate") {
                onDuplicate()
            }
            Divider()
            Button("Close", role: .destructive) {
                onClose()
            }
        }
        .accessibilityIdentifier("TabItem")
        .accessibilityLabel(note.title)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : [.isButton])
    }

    private func commitRename() {
        isEditing = false
        let trimmed = editedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            onRename(trimmed)
        }
    }
}

#Preview {
    HStack {
        TabItemView(
            note: Note(title: "Selected Tab"),
            index: 0,
            isSelected: true,
            onSelect: {},
            onClose: {},
            onRename: { _ in },
            onDuplicate: {}
        )
        TabItemView(
            note: Note(title: "Another Tab"),
            index: 1,
            isSelected: false,
            onSelect: {},
            onClose: {},
            onRename: { _ in },
            onDuplicate: {}
        )
    }
    .padding()
}
