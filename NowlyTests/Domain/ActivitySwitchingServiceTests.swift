import Foundation
import Testing
@testable import Nowly

@Test func switchClosesPreviousAndCreatesNewEvent() async throws {
    let repository = InMemoryActivityEventRepository()
    let workID = UUID()
    let lunchID = UUID()
    let start = Date(timeIntervalSinceReferenceDate: 1_000)
    let now = Date(timeIntervalSinceReferenceDate: 2_000)
    let work = try ActivityEvent(activityDefinitionID: workID, startDate: start, endDate: nil, source: .app)
    try await repository.save(work)

    let service = ActivitySwitchingService(repository: repository, clock: FixedClock(now: now))
    let receipt = try await service.switchActivity(to: lunchID, source: .app)

    #expect(try await repository.event(id: work.id)?.endDate == now)
    #expect(try await repository.activeEvent()?.activityDefinitionID == lunchID)
    #expect(receipt.isUndoable)
}

@Test func selectingCurrentActivityDoesNotCreateDuplicateEvent() async throws {
    let repository = InMemoryActivityEventRepository()
    let activityID = UUID()
    let current = try ActivityEvent(activityDefinitionID: activityID, startDate: .distantPast, endDate: nil, source: .app)
    try await repository.save(current)

    let service = ActivitySwitchingService(repository: repository, clock: FixedClock(now: .distantFuture))
    let receipt = try await service.switchActivity(to: activityID, source: .app)

    #expect(receipt == .noChange)
    #expect(try await repository.activeEvent() == current)
}

@Test func undoRestoresPreviousOpenEvent() async throws {
    let repository = InMemoryActivityEventRepository()
    let workID = UUID()
    let lunchID = UUID()
    let work = try ActivityEvent(activityDefinitionID: workID, startDate: .distantPast, endDate: nil, source: .app)
    try await repository.save(work)
    let service = ActivitySwitchingService(repository: repository, clock: FixedClock(now: .now))

    let receipt = try await service.switchActivity(to: lunchID, source: .app)
    try await service.undo(receipt)

    #expect(try await repository.activeEvent() == work)
}
