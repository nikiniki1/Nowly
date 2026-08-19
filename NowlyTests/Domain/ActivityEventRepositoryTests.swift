import Foundation
import Testing
@testable import Nowly

@Test func deletesAllEventsInsideIntervalRegardlessOfActivity() async throws {
    let repository = InMemoryActivityEventRepository()
    let targetID = UUID()
    let otherID = UUID()
    let day = Date(timeIntervalSince1970: 86_400)
    let target = try ActivityEvent(activityDefinitionID: targetID, startDate: day, endDate: day.addingTimeInterval(60), source: .app)
    let outside = try ActivityEvent(activityDefinitionID: targetID, startDate: day.addingTimeInterval(86_400), endDate: day.addingTimeInterval(86_460), source: .app)
    let other = try ActivityEvent(activityDefinitionID: otherID, startDate: day, endDate: day.addingTimeInterval(60), source: .app)
    try await repository.save(target)
    try await repository.save(outside)
    try await repository.save(other)

    let deleted = try await repository.deleteEvents(in: DateInterval(start: day, duration: 86_400))

    #expect(deleted == 2)
    #expect(try await repository.event(id: target.id) == nil)
    #expect(try await repository.event(id: outside.id) == outside)
    #expect(try await repository.event(id: other.id) == nil)
}

@Test func deletesAllEvents() async throws {
    let repository = InMemoryActivityEventRepository()
    let first = try ActivityEvent(activityDefinitionID: UUID(), startDate: .distantPast, endDate: .distantPast.addingTimeInterval(60), source: .app)
    let second = try ActivityEvent(activityDefinitionID: UUID(), startDate: .now, endDate: .now.addingTimeInterval(60), source: .app)
    try await repository.save(first)
    try await repository.save(second)

    let deleted = try await repository.deleteEvents()

    #expect(deleted == 2)
    #expect(try await repository.event(id: first.id) == nil)
    #expect(try await repository.event(id: second.id) == nil)
}

@Test func archivedDefinitionsAreHiddenFromActivityPickersButRetainedForHistory() async throws {
    let repository = InMemoryActivityDefinitionRepository()
    let active = ActivityDefinition(id: UUID(), name: "Active", parentID: nil, icon: nil, isFavorite: false, isArchived: false, sortOrder: 0, createdAt: .now)
    let archived = ActivityDefinition(id: UUID(), name: "Archived", parentID: nil, icon: nil, isFavorite: false, isArchived: true, sortOrder: 1, createdAt: .now)
    try await repository.save(active)
    try await repository.save(archived)

    #expect(try await repository.topLevelDefinitions().map(\.id) == [active.id])
    #expect(try await repository.allDefinitions().map(\.id) == [active.id, archived.id])
}
