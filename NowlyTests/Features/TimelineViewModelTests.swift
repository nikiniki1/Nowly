import Foundation
import Testing
@testable import Nowly

@MainActor
@Test func deletingTimelineEventLeavesUntrackedGap() async throws {
    let repository = InMemoryActivityEventRepository()
    let day = Date(timeIntervalSinceReferenceDate: 0)
    let coding = try ActivityEvent(activityDefinitionID: UUID(), startDate: day, endDate: day.addingTimeInterval(3 * 60 * 60), source: .app)
    let lunch = try ActivityEvent(activityDefinitionID: UUID(), startDate: day.addingTimeInterval(3 * 60 * 60), endDate: day.addingTimeInterval(4 * 60 * 60), source: .app)
    try await repository.save(coding)
    try await repository.save(lunch)
    let model = TimelineViewModel(eventRepository: repository, day: day, timeZone: .gmt)

    await model.load()
    try await model.delete(eventID: lunch.id)

    #expect(model.events.map(\.id).contains(lunch.id) == false)
    #expect(try await repository.event(id: coding.id)?.endDate == lunch.startDate)
}
