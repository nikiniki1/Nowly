import SwiftUI

struct ActivityEventEditorView: View {
    let event: ActivityEvent
    let definitionRepository: any ActivityDefinitionRepository
    let onSave: (ActivityEvent) async throws -> Void
    let onDelete: () async throws -> Void

    @State private var startDate: Date
    @State private var endDate: Date
    @State private var hasEndDate: Bool
    @State private var note: String
    @State private var baseActivityID: UUID
    @State private var refinementActivityID: UUID?
    @State private var definitions: [ActivityDefinition] = []
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss

    init(event: ActivityEvent, definitionRepository: any ActivityDefinitionRepository, onSave: @escaping (ActivityEvent) async throws -> Void, onDelete: @escaping () async throws -> Void) {
        self.event = event
        self.definitionRepository = definitionRepository
        self.onSave = onSave
        self.onDelete = onDelete
        _startDate = State(initialValue: event.startDate)
        _endDate = State(initialValue: event.endDate ?? event.startDate.addingTimeInterval(60 * 60))
        _hasEndDate = State(initialValue: event.endDate != nil)
        _note = State(initialValue: event.note ?? "")
        _baseActivityID = State(initialValue: event.activityDefinitionID)
        _refinementActivityID = State(initialValue: nil)
    }

    var body: some View {
        Form {
            Picker("Категория", selection: $baseActivityID) {
                ForEach(rootActivities) { activity in
                    Text(activity.displayName).tag(activity.id)
                }
            }
            .onChange(of: baseActivityID) { _, _ in
                refinementActivityID = nil
            }

            if hasRefinements {
                NavigationLink {
                    if let baseActivity {
                        ActivityRefinementPickerView(
                            root: baseActivity,
                            definitions: definitions,
                            selectedActivityID: $refinementActivityID
                        )
                    }
                } label: {
                    LabeledContent("Уточнение", value: refinementName)
                }
            }
            DatePicker("Начало", selection: $startDate)
            Toggle("Есть окончание", isOn: $hasEndDate)
            if hasEndDate { DatePicker("Окончание", selection: $endDate) }
            TextField("Заметка", text: $note)
            if let errorMessage { Text(errorMessage).foregroundStyle(.red) }
            Button("Сохранить") { save() }
            Button("Удалить", role: .destructive) { delete() }
        }
        .navigationTitle("Изменить запись")
        .task { await loadDefinitions() }
    }

    private func save() {
        Task {
            do {
                let edited = try ActivityEvent(id: event.id, activityDefinitionID: refinementActivityID ?? baseActivityID, startDate: startDate, endDate: hasEndDate ? endDate : nil, createdAt: event.createdAt, updatedAt: .now, note: note.isEmpty ? nil : note, source: event.source)
                try await onSave(edited)
                dismiss()
            } catch {
                errorMessage = "Проверьте время: записи не должны пересекаться."
            }
        }
    }

    private func delete() {
        Task {
            do {
                try await onDelete()
                dismiss()
            } catch {
                errorMessage = "Не удалось удалить запись."
            }
        }
    }

    private var rootActivities: [ActivityDefinition] {
        definitions.filter { $0.parentID == nil && !$0.isArchived }
    }

    private var baseActivity: ActivityDefinition? {
        definitions.first { $0.id == baseActivityID }
    }

    private var hasRefinements: Bool {
        definitions.contains { $0.parentID == baseActivityID && !$0.isArchived }
    }

    private var refinementName: String {
        guard let refinementActivityID,
              let refinement = definitions.first(where: { $0.id == refinementActivityID }) else {
            return String(localized: "Без уточнения")
        }
        return refinement.displayName
    }

    private func loadDefinitions() async {
        definitions = (try? await definitionRepository.allDefinitions()) ?? []
        let selection = ActivityHierarchySelection.resolve(
            selectedActivityID: event.activityDefinitionID,
            definitions: definitions
        )
        baseActivityID = selection.baseActivityID
        refinementActivityID = selection.refinementActivityID
    }
}
