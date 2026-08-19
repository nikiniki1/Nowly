import SwiftData

@MainActor
final class AppDependencies {
    let modelContainer: ModelContainer
    let repository: SwiftDataActivityRepository
    let switchingService: ActivitySwitchingService

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        let repository = SwiftDataActivityRepository(modelContainer: modelContainer)
        self.repository = repository
        switchingService = ActivitySwitchingService(repository: repository, clock: SystemClock())
    }

    static func production() -> AppDependencies {
        do {
            return AppDependencies(modelContainer: try ActivityModelContainer.make())
        } catch {
            fatalError("Unable to create the local activity database: \(error)")
        }
    }
}
