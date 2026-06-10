import SwiftUI

struct ProjectsSheet: View {
    @EnvironmentObject private var store: NotesStore
    @Environment(\.dismiss) private var dismiss
    @State private var newName = ""
    @State private var newColorHex = NoteColor.palette[0].hex

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Projects")
                .font(.headline)

            if store.projects.isEmpty {
                Text("No projects yet. Add one below — each project gets a name and a color; its notes take that color with the name on top.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 4) {
                    ForEach(store.projects) { project in
                        HStack {
                            Circle()
                                .fill(Color(hex: project.colorHex))
                                .frame(width: 12, height: 12)
                            Text(project.name)
                            Spacer()
                            Text("\(store.notes.filter { $0.projectID == project.id }.count) notes")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Button {
                                store.deleteProject(project)
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                            .help("Delete project (notes are kept)")
                        }
                        .padding(.vertical, 3)
                    }
                }
            }

            Divider()

            HStack(spacing: 8) {
                TextField("New project name", text: $newName)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(addProject)
                Button("Add", action: addProject)
                    .disabled(newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            ColorSwatchPicker(selectedHex: $newColorHex)

            HStack {
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(16)
        .frame(width: 360)
    }

    private func addProject() {
        store.addProject(name: newName, colorHex: newColorHex)
        newName = ""
    }
}
