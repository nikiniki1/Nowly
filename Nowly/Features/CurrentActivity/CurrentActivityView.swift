import SwiftUI

struct CurrentActivityView: View {
    @Bindable var viewModel: CurrentActivityViewModel
    let eventRepository: any ActivityEventRepository
    let definitionRepository: any ActivityDefinitionRepository

    @State private var activeRefinementID: UUID?
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .center, spacing: 24) {
                    currentState

                    if viewModel.suggestions.isEmpty {
                        ContentUnavailableView("Нет избранных активностей", systemImage: "star", description: Text("Добавьте их во вкладке «Активности»."))
                    } else {
                        VStack(alignment: .center, spacing: 12) {
                            Text("Быстрый выбор")
                                .font(.headline)
                            ForEach(viewModel.suggestions, id: \.activity.id) { suggestion in
                                QuickActivityButton(
                                    activity: suggestion.activity,
                                    definitionRepository: definitionRepository,
                                    activeRefinementID: $activeRefinementID
                                ) { activity in
                                    Task { await viewModel.select(activity) }
                                }
                            }
                        }
                    }

                    if viewModel.canUndo {
                        Button("Отменить последнее действие") {
                            Task { await viewModel.undo() }
                        }
                        .buttonStyle(.bordered)
                    }

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.footnote)
                            .accessibilityAddTraits(.isStaticText)
                    }
                }
                .padding()
                .frame(maxWidth: 480)
                .frame(maxWidth: .infinity)
            }
            .navigationTitle("Сейчас")
            .task { await viewModel.load() }
            .onReceive(NotificationCenter.default.publisher(for: .activityDefinitionsDidChange)) { _ in
                Task { await viewModel.load() }
            }
            .sensoryFeedback(.selection, trigger: viewModel.selectionFeedbackID)
        }
    }

    private var currentState: some View {
        VStack(alignment: .center, spacing: 8) {
            Text("Что вы делаете сейчас?")
                .font(.title2.bold())
            Text(viewModel.currentActivity?.displayName ?? "Время не отслеживается")
                .font(.title3)
                .foregroundStyle(viewModel.currentActivity == nil ? .secondary : .primary)
        }
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.center)
    }

}
