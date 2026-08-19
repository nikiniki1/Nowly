import AppIntents

struct StartFavoriteActivityIntent: AppIntent {
    static let title: LocalizedStringResource = "Начать избранную активность"
    static let openAppWhenRun = false

    @Parameter(title: "Активность") var activity: FavoriteActivityEntity

    init() {}

    init(activity: FavoriteActivityEntity) {
        self.activity = activity
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let dependencies = await MainActor.run { AppDependencies.production() }
        guard let definition = try await dependencies.repository.definition(id: activity.id), definition.isFavorite, !definition.isArchived else {
            return .result(dialog: "Эта активность больше недоступна.")
        }

        _ = try await dependencies.switchingService.switchActivity(to: definition.id, source: .shortcut)
        return .result(dialog: "Начинаю: \(definition.displayName)")
    }
}
