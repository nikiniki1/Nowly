import SwiftUI

struct TimelineView: View {
    @State private var viewModel: TimelineViewModel
    @State private var activityNames: [UUID: String] = [:]
    let definitionRepository: any ActivityDefinitionRepository

    init(eventRepository: any ActivityEventRepository, definitionRepository: any ActivityDefinitionRepository) {
        _viewModel = State(initialValue: TimelineViewModel(eventRepository: eventRepository))
        self.definitionRepository = definitionRepository
    }

    var body: some View {
        List(viewModel.events) { event in
            NavigationLink {
                ActivityEventEditorView(event: event, definitionRepository: definitionRepository) { edited in
                    try await viewModel.save(edited)
                } onDelete: {
                    try await viewModel.delete(eventID: event.id)
                }
            } label: {
                TimelineEventRow(event: event, name: activityNames[event.activityDefinitionID] ?? "Активность")
            }
        }
        .navigationTitle("Сегодня")
        .onAppear {
            Task { await viewModel.load() }
        }
        .task {
            async let definitionsLoad = definitionRepository.allDefinitions()

            let definitions = (try? await definitionsLoad) ?? []
            activityNames = Dictionary(uniqueKeysWithValues: definitions.map { ($0.id, $0.displayName) })
        }
        .onReceive(NotificationCenter.default.publisher(for: .activityHistoryDidChange)) { _ in
            Task { await viewModel.load() }
        }
    }
}

private struct TimelineEventRow: View {
    let event: ActivityEvent
    let name: String

    var body: some View {
        HStack {
            Text(event.startDate, style: .time)
                .monospacedDigit()
            VStack(alignment: .leading) {
                Text(name)
                Text(event.endDate.map { "до \($0.formatted(date: .omitted, time: .shortened))" } ?? "сейчас")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
