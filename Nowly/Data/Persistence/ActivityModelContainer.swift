import SwiftData

enum ActivityModelContainer {
    static let appGroupIdentifier = "group.selfhost.habit-tracker"

    static func make(isStoredInMemoryOnly: Bool = false) throws -> ModelContainer {
        let schema = Schema([StoredActivityDefinition.self, StoredActivityEvent.self])
#if targetEnvironment(simulator)
        let groupContainer: ModelConfiguration.GroupContainer = .none
#else
        let groupContainer: ModelConfiguration.GroupContainer = isStoredInMemoryOnly
            ? .none
            : .identifier(appGroupIdentifier)
#endif
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: isStoredInMemoryOnly,
            groupContainer: groupContainer
        )
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
