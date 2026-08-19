import Foundation
import Testing
@testable import Nowly

@Test func seedInsertionIsIdempotentInSwiftData() async throws {
    let container = try ActivityModelContainer.make(isStoredInMemoryOnly: true)
    let repository = SwiftDataActivityRepository(modelContainer: container)

    try await repository.seedInitialDefinitions()
    try await repository.seedInitialDefinitions()

    let sport = try await repository.topLevelDefinitions().filter { $0.name == "Спорт" }
    #expect(sport.count == 1)
}

@Test func seedingPreservesArchivedInitialDefinitions() async throws {
    let container = try ActivityModelContainer.make(isStoredInMemoryOnly: true)
    let repository = SwiftDataActivityRepository(modelContainer: container)
    try await repository.seedInitialDefinitions()
    let sport = try #require(await repository.allDefinitions().first { $0.name == "Спорт" && $0.parentID == nil })

    try await repository.save(sport.updating(isArchived: true))
    try await repository.seedInitialDefinitions()

    #expect(try await repository.definition(id: sport.id)?.isArchived == true)
}

@Test func persistedEventsAreAvailableToANewRepository() async throws {
    let container = try ActivityModelContainer.make(isStoredInMemoryOnly: true)
    let eventRepository = SwiftDataActivityRepository(modelContainer: container)
    let event = try ActivityEvent(
        id: UUID(),
        activityDefinitionID: UUID(),
        startDate: .distantPast,
        endDate: nil,
        source: .app
    )

    try await eventRepository.save(event)

    let reader = SwiftDataActivityRepository(modelContainer: container)
    #expect(try await reader.activeEvent() == event)
}

@Test func deletesAllPersistedEvents() async throws {
    let container = try ActivityModelContainer.make(isStoredInMemoryOnly: true)
    let writer = SwiftDataActivityRepository(modelContainer: container)
    let first = try ActivityEvent(activityDefinitionID: UUID(), startDate: .distantPast, endDate: .distantPast.addingTimeInterval(60), source: .app)
    let second = try ActivityEvent(activityDefinitionID: UUID(), startDate: .now, endDate: .now.addingTimeInterval(60), source: .app)
    try await writer.save(first)
    try await writer.save(second)

    #expect(try await writer.deleteEvents(in: nil) == 2)

    let reader = SwiftDataActivityRepository(modelContainer: container)
    #expect(try await reader.events(in: DateInterval(start: .distantPast, end: .distantFuture)).isEmpty)
}
