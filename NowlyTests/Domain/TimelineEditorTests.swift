import Foundation
import Testing
@testable import Nowly

@Test func insertingEventTruncatesEarlierOverlappingEvent() async throws {
    let repository = InMemoryActivityEventRepository()
    let codingID = UUID()
    let coding = try ActivityEvent(
        activityDefinitionID: codingID,
        startDate: Date(timeIntervalSinceReferenceDate: 0),
        endDate: Date(timeIntervalSinceReferenceDate: 4 * 60 * 60),
        source: .app
    )
    try await repository.save(coding)
    let lunch = try ActivityEvent(
        activityDefinitionID: UUID(),
        startDate: Date(timeIntervalSinceReferenceDate: 3 * 60 * 60),
        endDate: Date(timeIntervalSinceReferenceDate: 4 * 60 * 60),
        source: .app
    )

    let editor = TimelineEditor(repository: repository)
    try await editor.insert(lunch)

    #expect(try await repository.event(id: coding.id)?.endDate == lunch.startDate)
    #expect(try await repository.event(id: lunch.id) == lunch)
}

@Test func deletingEventLeavesUntrackedGap() async throws {
    let repository = InMemoryActivityEventRepository()
    let coding = try ActivityEvent(
        activityDefinitionID: UUID(),
        startDate: Date(timeIntervalSinceReferenceDate: 0),
        endDate: Date(timeIntervalSinceReferenceDate: 3 * 60 * 60),
        source: .app
    )
    let lunch = try ActivityEvent(
        activityDefinitionID: UUID(),
        startDate: Date(timeIntervalSinceReferenceDate: 3 * 60 * 60),
        endDate: Date(timeIntervalSinceReferenceDate: 4 * 60 * 60),
        source: .app
    )
    try await repository.save(coding)
    try await repository.save(lunch)
    let editor = TimelineEditor(repository: repository)

    try await editor.delete(id: lunch.id)

    #expect(try await repository.event(id: coding.id) == coding)
    #expect(try await repository.event(id: lunch.id) == nil)
}

@Test func updatingEventTruncatesEarlierEvent() async throws {
    let repository = InMemoryActivityEventRepository()
    let coding = try ActivityEvent(activityDefinitionID: UUID(), startDate: .distantPast, endDate: Date.distantPast.addingTimeInterval(4 * 60 * 60), source: .app)
    let lunch = try ActivityEvent(activityDefinitionID: UUID(), startDate: Date.distantPast.addingTimeInterval(4 * 60 * 60), endDate: Date.distantPast.addingTimeInterval(5 * 60 * 60), source: .app)
    try await repository.save(coding)
    try await repository.save(lunch)
    let changedLunch = try ActivityEvent(id: lunch.id, activityDefinitionID: lunch.activityDefinitionID, startDate: Date.distantPast.addingTimeInterval(3 * 60 * 60), endDate: lunch.endDate, source: .app)

    try await TimelineEditor(repository: repository).update(changedLunch)

    #expect(try await repository.event(id: coding.id)?.endDate == changedLunch.startDate)
}
