import Foundation

struct CurrentActivitySnapshot: Sendable, Equatable {
    let currentActivity: ActivityDefinition?
    let currentStartedAt: Date?
    let suggestions: [ActivityDefinition]
}

enum CurrentActivitySnapshotBuilder {
    static func make(
        eventRepository: any ActivityEventRepository,
        definitionRepository: any ActivityDefinitionRepository,
        rankingService: any ActivityRankingService = DeterministicActivityRankingService(),
        now: Date = Date(),
        suggestionLimit: Int
    ) async throws -> CurrentActivitySnapshot {
        let activeEvent = try await eventRepository.activeEvent()
        let currentActivity: ActivityDefinition? = if let activeEvent {
            try await definitionRepository.definition(id: activeEvent.activityDefinitionID)
        } else {
            nil
        }
        let definitions = try await definitionRepository.topLevelDefinitions()
        let context = ActivityContext(
            now: now,
            timeZone: .current,
            currentActivityID: currentActivity?.id,
            previousActivityID: nil,
            usage: [:]
        )
        let suggestions = rankingService
            .rank(activities: definitions, context: context, limit: suggestionLimit)
            .map(\.activity)
        return CurrentActivitySnapshot(
            currentActivity: currentActivity,
            currentStartedAt: activeEvent?.startDate,
            suggestions: suggestions
        )
    }
}
