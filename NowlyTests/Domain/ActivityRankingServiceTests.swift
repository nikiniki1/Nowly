import Foundation
import Testing
@testable import Nowly

@Test func favoriteOutranksEquallyUsedActivity() {
    let now = Date(timeIntervalSinceReferenceDate: 1_000)
    let favorite = ActivityDefinition(id: UUID(), name: "Sport", parentID: nil, icon: nil, isFavorite: true, isArchived: false, sortOrder: 1, createdAt: now)
    let regular = ActivityDefinition(id: UUID(), name: "Work", parentID: nil, icon: nil, isFavorite: false, isArchived: false, sortOrder: 0, createdAt: now)
    let context = ActivityContext(now: now, timeZone: .gmt, currentActivityID: nil, previousActivityID: nil, usage: [:])

    let ranked = DeterministicActivityRankingService().rank(activities: [regular, favorite], context: context, limit: 4)

    #expect(ranked.first?.activity.id == favorite.id)
}

@Test func currentAndArchivedActivitiesAreExcluded() {
    let now = Date(timeIntervalSinceReferenceDate: 1_000)
    let current = ActivityDefinition(id: UUID(), name: "Work", parentID: nil, icon: nil, isFavorite: true, isArchived: false, sortOrder: 0, createdAt: now)
    let archived = ActivityDefinition(id: UUID(), name: "Old", parentID: nil, icon: nil, isFavorite: true, isArchived: true, sortOrder: 1, createdAt: now)
    let available = ActivityDefinition(id: UUID(), name: "Break", parentID: nil, icon: nil, isFavorite: false, isArchived: false, sortOrder: 2, createdAt: now)
    let context = ActivityContext(now: now, timeZone: .gmt, currentActivityID: current.id, previousActivityID: nil, usage: [:])

    let ranked = DeterministicActivityRankingService().rank(activities: [current, archived, available], context: context, limit: 4)

    #expect(ranked.map(\.activity.id) == [available.id])
}

@Test func coldStartMorningPrioritizesSleep() {
    let sleep = ActivityDefinition(id: UUID(), name: "Сон", parentID: nil, icon: nil, isFavorite: false, isArchived: false, sortOrder: 4, createdAt: .distantPast)
    let work = ActivityDefinition(id: UUID(), name: "Работа", parentID: nil, icon: nil, isFavorite: false, isArchived: false, sortOrder: 0, createdAt: .distantPast)
    let context = ActivityContext(
        now: Date(timeIntervalSince1970: 1_787_126_400),
        timeZone: TimeZone(secondsFromGMT: 0)!,
        currentActivityID: nil,
        previousActivityID: nil,
        usage: [:]
    )

    let ranked = DeterministicActivityRankingService().rank(activities: [work, sleep], context: context, limit: 2)

    #expect(ranked.first?.activity.id == sleep.id)
}
