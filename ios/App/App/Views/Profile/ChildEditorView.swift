import SwiftUI

struct ChildEditorView: View {
    @Environment(\.dismiss) var dismiss
    let parentId: String
    var existing: Child?
    let onSave: (Child) async throws -> Void

    @State private var fullName = ""
    @State private var dateOfBirth = Date()
    @State private var hasDOB = false
    @State private var gender = ""
    @State private var position = ""
    @State private var notes = ""
    @State private var isSaving = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Player Info") {
                    TextField("Full Name", text: $fullName)

                    Toggle("Set Date of Birth", isOn: $hasDOB)
                    if hasDOB {
                        DatePicker("Birthday", selection: $dateOfBirth, displayedComponents: .date)
                    }
                }

                Section("Details") {
                    Picker("Gender", selection: $gender) {
                        Text("Not specified").tag("")
                        ForEach(Child.genders, id: \.self) { g in
                            Text(Child.genderLabel(g)).tag(g)
                        }
                    }

                    Picker("Position", selection: $position) {
                        Text("Not specified").tag("")
                        ForEach(Child.positions, id: \.self) { p in
                            Text(p).tag(p)
                        }
                    }
                }

                Section("Notes") {
                    TextField("Optional notes (injuries, goals…)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                if let error {
                    Section {
                        Text(error).foregroundStyle(.red).font(.footnote)
                    }
                }
            }
            .navigationTitle(existing == nil ? "Add Player" : "Edit Player")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await save() }
                    }
                    .disabled(fullName.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                }
            }
        }
        .onAppear { populate() }
    }

    private func populate() {
        guard let c = existing else { return }
        fullName = c.fullName
        gender = c.gender ?? ""
        position = c.position ?? ""
        notes = c.notes ?? ""
        if let dobStr = c.dateOfBirth,
           let date = ISO8601DateFormatter().date(from: dobStr) {
            dateOfBirth = date
            hasDOB = true
        }
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }
        let dobStr: String? = hasDOB ? ISO8601DateFormatter().string(from: dateOfBirth) : nil
        let child = Child(
            id: existing?.id ?? UUID().uuidString,
            parentId: parentId,
            fullName: fullName.trimmingCharacters(in: .whitespaces),
            dateOfBirth: dobStr,
            gender: gender.isEmpty ? nil : gender,
            position: position.isEmpty ? nil : position,
            notes: notes.isEmpty ? nil : notes
        )
        do {
            try await onSave(child)
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
    }
}
