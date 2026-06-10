import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject private var store: NotesStore
    @Environment(\.openWindow) private var openWindow

    private let previewLimit = 6

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Sticky Notes")
                    .font(.headline)
                Spacer()
                Button {
                    newNote()
                } label: {
                    Image(systemName: "plus")
                }
                .help("New note")
                Button {
                    openAllNotes()
                } label: {
                    Image(systemName: "rectangle.grid.2x2")
                }
                .help("Show all notes")
            }

            Divider()

            if store.activeNotes.isEmpty {
                Text("No notes yet")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 16)
            } else {
                ScrollView {
                    VStack(spacing: 6) {
                        ForEach(store.sortedNotes.prefix(previewLimit)) { note in
                            MenuNoteRow(
                                note: note,
                                project: store.project(for: note),
                                onDone: { store.markDone(note) },
                                onDelete: { store.delete(note) }
                            )
                            .contentShape(Rectangle())
                            .onTapGesture { openEditor(note.id) }
                        }
                    }
                }
                .frame(minHeight: 140, maxHeight: 330)

                if store.activeNotes.count > previewLimit {
                    Button("Show all \(store.activeNotes.count) notes…") {
                        openAllNotes()
                    }
                    .buttonStyle(.link)
                    .font(.callout)
                }
            }

            Divider()

            HStack {
                Text("\(store.activeNotes.count) note\(store.activeNotes.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Quit") { NSApp.terminate(nil) }
                    .buttonStyle(.plain)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .frame(width: 320)
    }

    private func newNote() {
        let note = store.addNote()
        openEditor(note.id)
    }

    private func openEditor(_ id: UUID) {
        activateApp()
        openWindow(id: WindowID.noteEditor, value: id)
    }

    private func openAllNotes() {
        activateApp()
        openWindow(id: WindowID.allNotes)
    }
}

struct MenuNoteRow: View {
    let note: Note
    let project: Project?
    var onDone: () -> Void
    var onDelete: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            VStack(alignment: .leading, spacing: 3) {
                if let project {
                    Text(project.name.uppercased())
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.black.opacity(0.6))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1.5)
                        .background(Capsule().fill(Color.black.opacity(0.1)))
                }
                Text(note.text.isEmpty ? "Empty note" : note.text)
                    .font(.system(size: 12))
                    .foregroundStyle(.black.opacity(note.text.isEmpty ? 0.4 : 0.85))
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 7) {
                Button(action: onDone) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 11))
                        .foregroundStyle(.black.opacity(0.45))
                }
                .buttonStyle(.plain)
                .help("Mark done")

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 11))
                        .foregroundStyle(.black.opacity(0.45))
                }
                .buttonStyle(.plain)
                .help("Delete note")
            }
        }
        .padding(8)
        .padding(.leading, note.priority == .none ? 0 : 5)
        .background(Color(hex: project?.colorHex ?? note.colorHex))
        .overlay(alignment: .leading) {
            if note.priority != .none {
                Rectangle()
                    .fill(note.priority.color)
                    .frame(width: 5)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 7))
    }
}
