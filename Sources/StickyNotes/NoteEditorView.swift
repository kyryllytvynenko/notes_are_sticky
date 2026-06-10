import SwiftUI

/// Resolves a note ID to a live binding into the store, so edits persist
/// immediately. Shows a placeholder if the note was deleted elsewhere.
struct NoteEditorWindow: View {
    @EnvironmentObject private var store: NotesStore
    let noteID: UUID

    var body: some View {
        if let index = store.notes.firstIndex(where: { $0.id == noteID }) {
            NoteEditorView(note: $store.notes[index])
        } else {
            Text("This note was deleted.")
                .foregroundStyle(.secondary)
                .frame(width: 340, height: 400)
        }
    }
}

struct NoteEditorView: View {
    @EnvironmentObject private var store: NotesStore
    @Environment(\.dismiss) private var dismiss
    @Binding var note: Note
    @State private var showNewProject = false

    private var project: Project? { store.project(for: note) }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().opacity(0.3)

            TextEditor(text: $note.text)
                .font(.system(size: 14))
                .foregroundStyle(.black.opacity(0.85))
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)

            Divider().opacity(0.3)
            footer
        }
        .background(Color(hex: store.colorHex(for: note)))
        // Hidden button so ⌘↩ confirms the note and closes the editor
        // (notes save as you type — this just dismisses the window).
        .background(
            Button("") { dismiss() }
                .keyboardShortcut(.return, modifiers: .command)
                .hidden()
        )
        // Note backgrounds are always light pastels — force light controls so
        // dark mode doesn't render menu labels and text in white.
        .environment(\.colorScheme, .light)
        .frame(minWidth: 320, idealWidth: 340, minHeight: 360, idealHeight: 400)
        .onChange(of: note.text) { _, _ in
            note.updatedAt = Date()
        }
        .sheet(isPresented: $showNewProject) {
            NewProjectSheet { project in
                note.projectID = project.id
            }
            .environmentObject(store)
        }
    }

    private var header: some View {
        VStack(spacing: 0) {
            if let project {
                Text(project.name.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.black.opacity(0.65))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 3)
                    .background(Color.black.opacity(0.08))
            }

            HStack(spacing: 8) {
                projectMenu
                Spacer()
                priorityMenu
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
        }
    }

    private var projectMenu: some View {
        Menu {
            Button("No project") { note.projectID = nil }
            ForEach(store.projects) { project in
                Button {
                    note.projectID = project.id
                } label: {
                    if note.projectID == project.id {
                        Label(project.name, systemImage: "checkmark")
                    } else {
                        Text(project.name)
                    }
                }
            }
            Divider()
            Button("New Project…") { showNewProject = true }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "folder")
                    .font(.system(size: 10))
                Text(project?.name ?? "No project")
            }
            .editorChip()
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .menuIndicator(.hidden)
        .fixedSize()
    }

    private var priorityMenu: some View {
        Menu {
            ForEach(Priority.allCases.reversed()) { priority in
                Toggle(isOn: priorityBinding(priority)) {
                    Label {
                        Text(priority.label)
                    } icon: {
                        Image(nsImage: priority.dotImage)
                    }
                }
            }
        } label: {
            Text(note.priority.label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(Capsule().fill(note.priority.color))
                .contentShape(Capsule())
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .menuIndicator(.hidden)
        .fixedSize()
    }

    private func priorityBinding(_ priority: Priority) -> Binding<Bool> {
        Binding(
            get: { note.priority == priority },
            set: { isOn in
                guard isOn else { return }
                note.priority = priority
                note.updatedAt = Date()
            }
        )
    }

    private var footer: some View {
        HStack {
            if project == nil {
                ColorSwatchPicker(selectedHex: $note.colorHex)
            }
            Spacer()
            Button {
                store.markDone(note)
                dismiss()
            } label: {
                Image(systemName: "checkmark.circle")
                    .foregroundStyle(.black.opacity(0.55))
            }
            .buttonStyle(.plain)
            .help("Mark done (moves to archive)")

            Button {
                store.delete(note)
                dismiss()
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(.black.opacity(0.5))
            }
            .buttonStyle(.plain)
            .help("Delete note")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }
}

private extension View {
    /// Dark, readable control chip that contrasts with any pastel note color.
    func editorChip() -> some View {
        self
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(.black.opacity(0.75))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(Color.black.opacity(0.08)))
            .contentShape(Capsule())
    }
}

struct ColorSwatchPicker: View {
    @Binding var selectedHex: String

    var body: some View {
        HStack(spacing: 5) {
            ForEach(NoteColor.palette) { color in
                Circle()
                    .fill(Color(hex: color.hex))
                    .frame(width: 17, height: 17)
                    .overlay(
                        Circle()
                            .strokeBorder(
                                selectedHex == color.hex ? Color.black.opacity(0.6) : Color.black.opacity(0.12),
                                lineWidth: selectedHex == color.hex ? 2 : 1
                            )
                    )
                    .onTapGesture { selectedHex = color.hex }
                    .help(color.name)
            }
        }
    }
}

struct NewProjectSheet: View {
    @EnvironmentObject private var store: NotesStore
    @Environment(\.dismiss) private var dismiss
    var onCreate: ((Project) -> Void)? = nil

    @State private var name = ""
    @State private var colorHex = NoteColor.palette[0].hex

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("New Project")
                .font(.headline)
            TextField("Project name", text: $name)
                .textFieldStyle(.roundedBorder)
                .onSubmit(create)
            ColorSwatchPicker(selectedHex: $colorHex)
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Add", action: create)
                    .keyboardShortcut(.defaultAction)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(16)
        .frame(width: 300)
    }

    private func create() {
        guard let project = store.addProject(name: name, colorHex: colorHex) else { return }
        onCreate?(project)
        dismiss()
    }
}
