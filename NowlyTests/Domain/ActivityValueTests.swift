import Foundation
import Testing
@testable import Nowly

@Test func eventRejectsEndBeforeStart() {
    #expect(throws: ActivityEvent.ValidationError.invalidInterval) {
        _ = try ActivityEvent(
            activityDefinitionID: UUID(),
            startDate: .distantFuture,
            endDate: .distantPast,
            source: .app
        )
    }
}

@Test func repositoryReturnsOnlyOpenEvent() async throws {
    let repository = InMemoryActivityEventRepository()
    let open = try ActivityEvent(
        activityDefinitionID: UUID(),
        startDate: .now,
        endDate: nil,
        source: .app
    )

    try await repository.save(open)

    #expect(try await repository.activeEvent() == open)
}

@Test func definitionRepositoryReturnsAllDefinitionsInTreeOrder() async throws {
    let repository = InMemoryActivityDefinitionRepository()
    let parent = ActivityDefinition(id: UUID(), name: "Sport", parentID: nil, icon: nil, isFavorite: false, isArchived: false, sortOrder: 1, createdAt: .distantPast)
    let child = ActivityDefinition(id: UUID(), name: "Gym", parentID: parent.id, icon: nil, isFavorite: false, isArchived: false, sortOrder: 0, createdAt: .distantPast)
    try await repository.save(parent)
    try await repository.save(child)

    #expect(try await repository.allDefinitions().map(\.id) == [child.id, parent.id])
}
