import SwiftUI

struct TabItemView: View {
    let note: Note
    let isSelected: Bool
    let onSelect: () -> Void
    let onClose: () -> Void
    let onRename: (String) -> Void
    let onDuplicate: () -> Void

    @State private var isEditing = false
    @State private var editedTitle = ""
    @State private var isHovering = false

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
                Text(note.title)
                    .font(.system(size: 12))
                    .lineLimit(1)
                    .truncationMode(.tail)
            }

            if isHovering || isSelected {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("CloseTabButton")
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
        .onHover { hovering in
            isHovering = hovering
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
            isSelected: true,
            onSelect: {},
            onClose: {},
            onRename: { _ in },
            onDuplicate: {}
        )
        TabItemView(
            note: Note(title: "Another Tab"),
            isSelected: false,
            onSelect: {},
            onClose: {},
            onRename: { _ in },
            onDuplicate: {}
        )
    }
    .padding()
}
