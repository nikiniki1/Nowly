import SwiftUI

struct ActivityPickerView: View {
    let root: ActivityDefinition
    let definitionRepository: any ActivityDefinitionRepository
    let onSelect: (ActivityDefinition) -> Void

    @State private var children: [ActivityDefinition] = []
    @State private var isLoading = true
    @State private var refinementRoot: ActivityDefinition?
    @State private var activityPendingDeletion: ActivityDefinition?
    @State private var isAddingActivity = false
    @State private var newActivityName = ""
    @State private var errorMessage: String?
    @State private var selectedActivityName: String?

    var body: some View {
        List {
            ForEach(children) { activity in
                activityRow(activity)
            }
        }
        .overlay {
            if !isLoading && children.isEmpty {
                ContentUnavailableView("Нет более точных вариантов", systemImage: "list.bullet")
            }
        }
        .navigationTitle(root.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $refinementRoot) { activity in
            ActivityPickerView(root: activity, definitionRepository: definitionRepository, onSelect: onSelect)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { isAddingActivity = true } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Добавить уточнение")
            }
        }
        .alert("Новое уточнение", isPresented: $isAddingActivity) {
            TextField("Название", text: $newActivityName)
            Button("Добавить") { Task { await addActivity() } }
            Button("Отмена", role: .cancel) { newActivityName = "" }
        }
        .confirmationDialog(
            "Удалить «\(activityPendingDeletion?.displayName ?? "")»?",
            isPresented: Binding(
                get: { activityPendingDeletion != nil },
                set: { if !$0 { activityPendingDeletion = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Удалить", role: .destructive) {
                if let activityPendingDeletion {
                    Task { await archive(activityPendingDeletion) }
                }
            }
        } message: {
            Text("Активность исчезнет из списка, но её записи останутся в истории.")
        }
        .alert("Не удалось изменить активности", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .task(id: root.id) {
            await loadChildren()
        }
        .task(id: selectedActivityName) { await dismissSelectionToast() }
        .overlay(alignment: .bottom) {
            if let selectedActivityName {
                ActivitySelectionToast(activityName: selectedActivityName)
                    .padding(.bottom, 16)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.snappy(duration: 0.25), value: selectedActivityName)
    }

    private func activityRow(_ activity: ActivityDefinition) -> some View {
        HStack {
            Button { select(activity) } label: {
                activityTitle(activity)
            }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())

            Button {
                refinementRoot = activity
            } label: {
                Image(systemName: "chevron.right")
                    .frame(minWidth: 44, minHeight: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("Уточнить: \(activity.displayName)"))
        }
        .contextMenu {
            Button(activity.isFavorite ? String(localized: "Убрать из избранного") : String(localized: "В избранное"), systemImage: activity.isFavorite ? "star.slash" : "star") {
                Task { await toggleFavorite(activity) }
            }
            Button("Удалить", systemImage: "trash", role: .destructive) {
                activityPendingDeletion = activity
            }
        }
    }

    private func activityTitle(_ activity: ActivityDefinition) -> some View {
        HStack(spacing: 6) {
            Text(activity.displayName)
            if activity.isFavorite {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                    .accessibilityLabel("Избранное")
            }
        }
    }

    private func loadChildren() async {
        isLoading = true
        children = (try? await definitionRepository.children(of: root.id)) ?? []
        isLoading = false
    }

    private func select(_ activity: ActivityDefinition) {
        onSelect(activity)
        selectedActivityName = activity.displayName
    }

    private func dismissSelectionToast() async {
        guard let selectedActivityName else { return }
        try? await Task.sleep(for: .seconds(1.5))
        guard self.selectedActivityName == selectedActivityName else { return }
        self.selectedActivityName = nil
    }

    private func addActivity() async {
        let name = newActivityName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        do {
            try await definitionRepository.save(ActivityDefinition(
                id: UUID(), name: name, parentID: root.id, icon: nil, isFavorite: false,
                isArchived: false, sortOrder: (children.map(\.sortOrder).max() ?? -1) + 1, createdAt: .now
            ))
            newActivityName = ""
            await loadChildren()
            definitionsDidChange()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func toggleFavorite(_ activity: ActivityDefinition) async {
        do {
            try await definitionRepository.save(activity.updating(isFavorite: !activity.isFavorite))
            await loadChildren()
            definitionsDidChange()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func archive(_ activity: ActivityDefinition) async {
        do {
            try await archiveRecursively(activity)
            activityPendingDeletion = nil
            await loadChildren()
            definitionsDidChange()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func archiveRecursively(_ activity: ActivityDefinition) async throws {
        let descendants = try await definitionRepository.children(of: activity.id)
        for descendant in descendants {
            try await archiveRecursively(descendant)
        }
        try await definitionRepository.save(activity.updating(isFavorite: false, isArchived: true))
    }

    private func definitionsDidChange() {
        NotificationCenter.default.post(name: .activityDefinitionsDidChange, object: nil)
    }
}
