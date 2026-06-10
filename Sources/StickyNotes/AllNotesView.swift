import SwiftUI

enum ProjectFilter: Hashable {
    case all
    case none
    case project(UUID)
}

struct AllNotesView: View {
    @EnvironmentObject private var store: NotesStore
    @Environment(\.openWindow) private var openWindow
    @State private var filter: ProjectFilter = .all
    @State private var searchText = ""
    @State private var showArchive = false
    @State private var showProjects = false

    private var visibleNotes: [Note] {
        var list = showArchive ? store.archivedNotes : store.sortedNotes

        switch filter {
        case .all:
            break
        case .none:
            list = list.filter { $0.projectID == nil }
        case .project(let id):
            list = list.filter { $0.projectID == id }
        }

        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        if !query.isEmpty {
            list = list.filter { note in
                note.text.lowercased().contains(query)
                    || (store.project(for: note)?.name.lowercased().contains(query) ?? false)
            }
        }
        return list
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()

            if visibleNotes.isEmpty {
                Spacer()
                Text(emptyMessage)
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                ScrollView {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 210, maximum: 290), spacing: 12)],
                        spacing: 12
                    ) {
                        ForEach(visibleNotes) { note in
                            NoteCard(
                                note: note,
                                project: store.project(for: note),
                                onDone: { note.isDone ? store.restore(note) : store.markDone(note) },
                                onDelete: { store.delete(note) }
                            )
                            .contentShape(Rectangle())
                            .onTapGesture { openEditor(note.id) }
                            .contextMenu { noteContextMenu(note) }
                            .frame(maxHeight: .infinity, alignment: .top)
                        }
                    }
                    .padding(14)
                }
            }
        }
        .frame(minWidth: 560, minHeight: 400)
        .sheet(isPresented: $showProjects) {
            ProjectsSheet()
                .environmentObject(store)
        }
    }

    private var emptyMessage: String {
        if !searchText.isEmpty { return "No notes match “\(searchText)”." }
        if showArchive { return "Archive is empty." }
        return store.activeNotes.isEmpty ? "No notes yet — create one!" : "No notes match this filter."
    }

    private var header: some View {
        HStack(spacing: 10) {
            HStack(spacing: 5) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 11))
                TextField("Search notes & projects", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(RoundedRectangle(cornerRadius: 6).fill(.quaternary.opacity(0.5)))
            .frame(maxWidth: 220)

            Picker("Filter", selection: $filter) {
                Text("All notes").tag(ProjectFilter.all)
                Text("No project").tag(ProjectFilter.none)
                if !store.projects.isEmpty {
                    Divider()
                    ForEach(store.projects) { project in
                        Text(project.name).tag(ProjectFilter.project(project.id))
                    }
                }
            }
            .labelsHidden()
            .frame(maxWidth: 160)

            Spacer()

            Toggle(isOn: $showArchive) {
                Label("Archive", systemImage: "archivebox")
            }
            .toggleStyle(.button)
            .help("Show done notes")

            Button {
                showProjects = true
            } label: {
                Label("Projects", systemImage: "folder")
            }

            Button {
                newNote()
            } label: {
                Label("New Note", systemImage: "plus")
            }
            .keyboardShortcut("n", modifiers: .command)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private func noteContextMenu(_ note: Note) -> some View {
        if note.isDone {
            Button("Restore") { store.restore(note) }
            Divider()
            Button("Delete Permanently", role: .destructive) { store.delete(note) }
        } else {
            Button("Mark Done") { store.markDone(note) }
            Menu("Priority") {
                ForEach(Priority.allCases.reversed()) { priority in
                    Toggle(isOn: Binding(
                        get: { note.priority == priority },
                        set: { isOn in
                            guard isOn else { return }
                            update(note) { $0.priority = priority }
                        }
                    )) {
                        Label {
                            Text(priority.label)
                        } icon: {
                            Image(nsImage: priority.dotImage)
                        }
                    }
                }
            }
            Menu("Project") {
                Button("No project") {
                    update(note) { $0.projectID = nil }
                }
                ForEach(store.projects) { project in
                    Button(project.name) {
                        update(note) { $0.projectID = project.id }
                    }
                }
            }
            if note.projectID == nil {
                Menu("Color") {
                    ForEach(NoteColor.palette) { color in
                        Button(color.name) {
                            update(note) { $0.colorHex = color.hex }
                        }
                    }
                }
            }
            Divider()
            Button("Delete", role: .destructive) {
                store.delete(note)
            }
        }
    }

    private func update(_ note: Note, _ change: (inout Note) -> Void) {
        guard let index = store.notes.firstIndex(where: { $0.id == note.id }) else { return }
        change(&store.notes[index])
        store.notes[index].updatedAt = Date()
    }

    private func newNote() {
        var projectID: UUID?
        if case .project(let id) = filter { projectID = id }
        let note = store.addNote(projectID: projectID)
        openEditor(note.id)
    }

    private func openEditor(_ id: UUID) {
        activateApp()
        openWindow(id: WindowID.noteEditor, value: id)
    }
}

struct NoteCard: View {
    let note: Note
    let project: Project?
    var onDone: () -> Void
    var onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let project {
                Text(project.name.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.black.opacity(0.65))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 3)
                    .background(Color.black.opacity(0.08))
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(note.text.isEmpty ? "Empty note" : note.text)
                    .font(.system(size: 13))
                    .foregroundStyle(.black.opacity(note.text.isEmpty ? 0.4 : 0.85))
                    .lineLimit(7)
                    .frame(maxWidth: .infinity, minHeight: 90, alignment: .topLeading)

                HStack(spacing: 5) {
                    if note.isDone {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.black.opacity(0.45))
                        Text("Done")
                            .font(.system(size: 10))
                            .foregroundStyle(.black.opacity(0.5))
                    } else if note.priority != .none {
                        Text(note.priority.label)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(note.priority.color))
                    }
                    Spacer()
                    Text(note.doneAt ?? note.updatedAt, format: .dateTime.day().month())
                        .font(.system(size: 10))
                        .foregroundStyle(.black.opacity(0.4))

                    Button(action: onDone) {
                        Image(systemName: note.isDone ? "arrow.uturn.backward.circle" : "checkmark.circle")
                            .font(.system(size: 12))
                            .foregroundStyle(.black.opacity(0.45))
                    }
                    .buttonStyle(.plain)
                    .help(note.isDone ? "Restore note" : "Mark done")

                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                            .foregroundStyle(.black.opacity(0.45))
                    }
                    .buttonStyle(.plain)
                    .help(note.isDone ? "Delete permanently" : "Delete note")
                }
            }
            .padding(10)
        }
        .background(Color(hex: project?.colorHex ?? note.colorHex))
        .clipShape(RoundedRectangle(cornerRadius: 9))
        .shadow(color: .black.opacity(0.12), radius: 3, y: 1)
        .opacity(note.isDone ? 0.75 : 1)
    }
}
