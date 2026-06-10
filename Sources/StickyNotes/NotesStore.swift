import Foundation
import Combine

@MainActor
final class NotesStore: ObservableObject {
    @Published var notes: [Note] = [] { didSet { save() } }
    @Published var projects: [Project] = [] { didSet { save() } }

    private struct Payload: Codable {
        var notes: [Note]
        var projects: [Project]
    }

    private let fileURL: URL
    private var isLoading = false

    init() {
        let dir = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("StickyNotes", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("notes.json")
        load()
    }

    private func load() {
        isLoading = true
        defer { isLoading = false }
        guard let data = try? Data(contentsOf: fileURL),
              let payload = try? JSONDecoder().decode(Payload.self, from: data)
        else { return }
        notes = payload.notes
        projects = payload.projects
    }

    private func save() {
        guard !isLoading else { return }
        let payload = Payload(notes: notes, projects: projects)
        if let data = try? JSONEncoder().encode(payload) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    // MARK: - Notes

    var activeNotes: [Note] {
        notes.filter { !$0.isDone }
    }

    /// Active notes, highest priority first, then most recently edited.
    var sortedNotes: [Note] {
        activeNotes.sorted { a, b in
            if a.priority != b.priority { return a.priority > b.priority }
            return a.updatedAt > b.updatedAt
        }
    }

    /// Done notes, most recently completed first.
    var archivedNotes: [Note] {
        notes.filter(\.isDone).sorted { ($0.doneAt ?? .distantPast) > ($1.doneAt ?? .distantPast) }
    }

    @discardableResult
    func addNote(projectID: UUID? = nil) -> Note {
        var note = Note()
        note.projectID = projectID
        notes.insert(note, at: 0)
        return note
    }

    func delete(_ note: Note) {
        notes.removeAll { $0.id == note.id }
    }

    func markDone(_ note: Note) {
        guard let i = notes.firstIndex(where: { $0.id == note.id }) else { return }
        notes[i].doneAt = Date()
    }

    func restore(_ note: Note) {
        guard let i = notes.firstIndex(where: { $0.id == note.id }) else { return }
        notes[i].doneAt = nil
        notes[i].updatedAt = Date()
    }

    func project(for note: Note) -> Project? {
        note.projectID.flatMap { id in projects.first { $0.id == id } }
    }

    /// A note with a project takes the project's color; otherwise its own.
    func colorHex(for note: Note) -> String {
        project(for: note)?.colorHex ?? note.colorHex
    }

    // MARK: - Projects

    @discardableResult
    func addProject(name: String, colorHex: String) -> Project? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let project = Project(name: trimmed, colorHex: colorHex)
        projects.append(project)
        return project
    }

    func deleteProject(_ project: Project) {
        projects.removeAll { $0.id == project.id }
        for i in notes.indices where notes[i].projectID == project.id {
            notes[i].projectID = nil
        }
    }
}
