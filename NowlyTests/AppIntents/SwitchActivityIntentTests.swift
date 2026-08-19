import Foundation
import Testing
@testable import Nowly

@Test func switchActivityIntentCreatesEventForAvailableDefinition() async throws {
    let events = InMemoryActivityEventRepository()
    let definitions = InMemoryActivityDefinitionRepository()
    let work = ActivityDefinition(id: UUID(), name: "Работа", parentID: nil, icon: nil, isFavorite: false, isArchived: false, sortOrder: 0, createdAt: Date(timeIntervalSince1970: 0))
    try await definitions.save(work)
    let service = ActivitySwitchingService(repository: events, clock: FixedClock(now: Date(timeIntervalSince1970: 1_000)))

    let receipt = try await SwitchActivityIntent.switchActivity(
        idString: work.id.uuidString,
        definitionRepository: definitions,
        switchingService: service
    )

    #expect(receipt.isUndoable)
    #expect(try await events.activeEvent()?.activityDefinitionID == work.id)
    #expect(try await events.activeEvent()?.source == .widget)
}

@Test func switchActivityIntentIgnoresArchivedDefinition() async throws {
    let events = InMemoryActivityEventRepository()
    let definitions = InMemoryActivityDefinitionRepository()
    let archived = ActivityDefinition(id: UUID(), name: "Старое", parentID: nil, icon: nil, isFavorite: false, isArchived: true, sortOrder: 0, createdAt: Date(timeIntervalSince1970: 0))
    try await definitions.save(archived)
    let service = ActivitySwitchingService(repository: events, clock: FixedClock(now: Date(timeIntervalSince1970: 1_000)))

    let receipt = try await SwitchActivityIntent.switchActivity(
        idString: archived.id.uuidString,
        definitionRepository: definitions,
        switchingService: service
    )

    #expect(receipt == .noChange)
    #expect(try await events.activeEvent() == nil)
}

@Test func switchActivityIntentIgnoresMalformedIdentifier() async throws {
    let events = InMemoryActivityEventRepository()
    let definitions = InMemoryActivityDefinitionRepository()
    let service = ActivitySwitchingService(repository: events, clock: FixedClock(now: Date(timeIntervalSince1970: 1_000)))

    let receipt = try await SwitchActivityIntent.switchActivity(
        idString: "not-a-uuid",
        definitionRepository: definitions,
        switchingService: service
    )

    #expect(receipt == .noChange)
    #expect(try await events.activeEvent() == nil)
}
