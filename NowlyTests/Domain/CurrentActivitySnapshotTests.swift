import Foundation
import Testing
@testable import Nowly

@Test func snapshotWithoutActiveEventOffersRankedSuggestions() async throws {
    let events = InMemoryActivityEventRepository()
    let definitions = InMemoryActivityDefinitionRepository()
    let now = Date(timeIntervalSince1970: 1_000)
    let work = ActivityDefinition(id: UUID(), name: "Проект", parentID: nil, icon: nil, isFavorite: false, isArchived: false, sortOrder: 0, createdAt: now)
    let rest = ActivityDefinition(id: UUID(), name: "Чтение", parentID: nil, icon: nil, isFavorite: false, isArchived: false, sortOrder: 1, createdAt: now)
    try await definitions.save(work)
    try await definitions.save(rest)

    let snapshot = try await CurrentActivitySnapshotBuilder.make(
        eventRepository: events,
        definitionRepository: definitions,
        rankingService: DeterministicActivityRankingService(),
        now: now,
        suggestionLimit: 2
    )

    #expect(snapshot.currentActivity == nil)
    #expect(snapshot.currentStartedAt == nil)
    #expect(snapshot.suggestions.map(\.id) == [work.id, rest.id])
}

@Test func snapshotExcludesCurrentActivityFromSuggestions() async throws {
    let events = InMemoryActivityEventRepository()
    let definitions = InMemoryActivityDefinitionRepository()
    let now = Date(timeIntervalSince1970: 1_000)
    let work = ActivityDefinition(id: UUID(), name: "Работа", parentID: nil, icon: nil, isFavorite: false, isArchived: false, sortOrder: 0, createdAt: now)
    let rest = ActivityDefinition(id: UUID(), name: "Отдых", parentID: nil, icon: nil, isFavorite: false, isArchived: false, sortOrder: 1, createdAt: now)
    try await definitions.save(work)
    try await definitions.save(rest)
    let active = try ActivityEvent(activityDefinitionID: work.id, startDate: now, endDate: nil, source: .app)
    try await events.save(active)

    let snapshot = try await CurrentActivitySnapshotBuilder.make(
        eventRepository: events,
        definitionRepository: definitions,
        rankingService: DeterministicActivityRankingService(),
        now: now,
        suggestionLimit: 2
    )

    #expect(snapshot.currentActivity?.id == work.id)
    #expect(snapshot.currentStartedAt == active.startDate)
    #expect(snapshot.suggestions.map(\.id) == [rest.id])
}

@Test func snapshotHonorsSuggestionLimit() async throws {
    let events = InMemoryActivityEventRepository()
    let definitions = InMemoryActivityDefinitionRepository()
    let now = Date(timeIntervalSince1970: 1_000)
    for order in 0..<4 {
        try await definitions.save(ActivityDefinition(id: UUID(), name: "A\(order)", parentID: nil, icon: nil, isFavorite: false, isArchived: false, sortOrder: order, createdAt: now))
    }

    let snapshot = try await CurrentActivitySnapshotBuilder.make(
        eventRepository: events,
        definitionRepository: definitions,
        rankingService: DeterministicActivityRankingService(),
        now: now,
        suggestionLimit: 2
    )

    #expect(snapshot.suggestions.count == 2)
}
