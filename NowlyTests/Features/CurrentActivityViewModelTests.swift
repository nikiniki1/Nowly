import Foundation
import Testing
@testable import Nowly

@MainActor
@Test func selectingSuggestionRefreshesCurrentActivityAndOffersUndo() async throws {
    let clock = FixedClock(now: Date(timeIntervalSince1970: 1_000))
    let events = InMemoryActivityEventRepository()
    let definitions = InMemoryActivityDefinitionRepository()
    let lunch = ActivityDefinition(id: UUID(), name: "Lunch", parentID: nil, icon: nil, isFavorite: false, isArchived: false, sortOrder: 0, createdAt: clock.now)
    try await definitions.save(lunch)
    let model = CurrentActivityViewModel(
        eventRepository: events,
        definitionRepository: definitions,
        switchingService: ActivitySwitchingService(repository: events, clock: clock),
        rankingService: DeterministicActivityRankingService(),
        clock: clock
    )

    await model.load()
    await model.select(lunch)

    #expect(model.currentActivity?.id == lunch.id)
    #expect(model.canUndo)
}

@MainActor
@Test func selectingQuickActivityKeepsQuickChoicesStable() async throws {
    let clock = FixedClock(now: Date(timeIntervalSince1970: 1_000))
    let events = InMemoryActivityEventRepository()
    let definitions = InMemoryActivityDefinitionRepository()
    let activities = (0..<4).map { index in
        ActivityDefinition(
            id: UUID(),
            name: "Activity \(index)",
            parentID: nil,
            icon: nil,
            isFavorite: false,
            isArchived: false,
            sortOrder: index,
            createdAt: clock.now
        )
    }
    for activity in activities {
        try await definitions.save(activity)
    }
    let model = CurrentActivityViewModel(
        eventRepository: events,
        definitionRepository: definitions,
        switchingService: ActivitySwitchingService(repository: events, clock: clock),
        rankingService: DeterministicActivityRankingService(),
        clock: clock
    )

    await model.load()
    let suggestionsBeforeSelection = model.suggestions.map(\.activity.id)
    await model.select(activities[0])

    #expect(model.suggestions.map(\.activity.id) == suggestionsBeforeSelection)
}

@MainActor
@Test func quickChoicesContainOnlyFavoriteActivitiesIncludingRefinements() async throws {
    let clock = FixedClock(now: Date(timeIntervalSince1970: 1_000))
    let events = InMemoryActivityEventRepository()
    let definitions = InMemoryActivityDefinitionRepository()
    let work = ActivityDefinition(id: UUID(), name: "Work", parentID: nil, icon: nil, isFavorite: false, isArchived: false, sortOrder: 0, createdAt: clock.now)
    let meeting = ActivityDefinition(id: UUID(), name: "Meeting", parentID: work.id, icon: nil, isFavorite: true, isArchived: false, sortOrder: 0, createdAt: clock.now)
    let rest = ActivityDefinition(id: UUID(), name: "Rest", parentID: nil, icon: nil, isFavorite: true, isArchived: false, sortOrder: 1, createdAt: clock.now)
    try await definitions.save(work)
    try await definitions.save(meeting)
    try await definitions.save(rest)
    let model = CurrentActivityViewModel(
        eventRepository: events,
        definitionRepository: definitions,
        switchingService: ActivitySwitchingService(repository: events, clock: clock),
        clock: clock
    )

    await model.load()

    #expect(model.suggestions.map(\.activity.id) == [meeting.id, rest.id])
}

@MainActor
@Test func quickChoicesShowEveryFavoriteActivity() async throws {
    let clock = FixedClock(now: Date(timeIntervalSince1970: 1_000))
    let events = InMemoryActivityEventRepository()
    let definitions = InMemoryActivityDefinitionRepository()
    let favorites = (0..<5).map { index in
        ActivityDefinition(
            id: UUID(), name: "Favorite \(index)", parentID: nil, icon: nil,
            isFavorite: true, isArchived: false, sortOrder: index, createdAt: clock.now
        )
    }
    for activity in favorites {
        try await definitions.save(activity)
    }
    let model = CurrentActivityViewModel(
        eventRepository: events,
        definitionRepository: definitions,
        switchingService: ActivitySwitchingService(repository: events, clock: clock),
        clock: clock
    )

    await model.load()

    #expect(model.suggestions.map(\.activity.id) == favorites.map(\.id))
}

@MainActor
@Test func togglingFavoritePersistsDefinitionChange() async throws {
    let clock = FixedClock(now: Date(timeIntervalSinceReferenceDate: 1_000))
    let events = InMemoryActivityEventRepository()
    let definitions = InMemoryActivityDefinitionRepository()
    let sport = ActivityDefinition(id: UUID(), name: "Sport", parentID: nil, icon: nil, isFavorite: false, isArchived: false, sortOrder: 0, createdAt: clock.now)
    try await definitions.save(sport)
    let model = CurrentActivityViewModel(eventRepository: events, definitionRepository: definitions, switchingService: ActivitySwitchingService(repository: events, clock: clock), clock: clock)

    await model.toggleFavorite(sport)

    #expect(try await definitions.definition(id: sport.id)?.isFavorite == true)
}

@MainActor
@Test func selectingSuggestionNotifiesActivityChanged() async throws {
    let clock = FixedClock(now: Date(timeIntervalSince1970: 1_000))
    let events = InMemoryActivityEventRepository()
    let definitions = InMemoryActivityDefinitionRepository()
    let lunch = ActivityDefinition(id: UUID(), name: "Lunch", parentID: nil, icon: nil, isFavorite: false, isArchived: false, sortOrder: 0, createdAt: clock.now)
    try await definitions.save(lunch)
    var notifications = 0
    let model = CurrentActivityViewModel(
        eventRepository: events,
        definitionRepository: definitions,
        switchingService: ActivitySwitchingService(repository: events, clock: clock),
        rankingService: DeterministicActivityRankingService(),
        clock: clock,
        onActivityChanged: { notifications += 1 }
    )

    await model.load()
    await model.select(lunch)

    #expect(notifications == 1)
}

@MainActor
@Test func reselectingCurrentActivityDoesNotNotify() async throws {
    let clock = FixedClock(now: Date(timeIntervalSince1970: 1_000))
    let events = InMemoryActivityEventRepository()
    let definitions = InMemoryActivityDefinitionRepository()
    let lunch = ActivityDefinition(id: UUID(), name: "Lunch", parentID: nil, icon: nil, isFavorite: false, isArchived: false, sortOrder: 0, createdAt: clock.now)
    try await definitions.save(lunch)
    var notifications = 0
    let model = CurrentActivityViewModel(
        eventRepository: events,
        definitionRepository: definitions,
        switchingService: ActivitySwitchingService(repository: events, clock: clock),
        rankingService: DeterministicActivityRankingService(),
        clock: clock,
        onActivityChanged: { notifications += 1 }
    )

    await model.load()
    await model.select(lunch)
    await model.select(lunch)

    #expect(notifications == 1)
}

@MainActor
@Test func undoNotifiesActivityChanged() async throws {
    let clock = FixedClock(now: Date(timeIntervalSince1970: 1_000))
    let events = InMemoryActivityEventRepository()
    let definitions = InMemoryActivityDefinitionRepository()
    let lunch = ActivityDefinition(id: UUID(), name: "Lunch", parentID: nil, icon: nil, isFavorite: false, isArchived: false, sortOrder: 0, createdAt: clock.now)
    try await definitions.save(lunch)
    var notifications = 0
    let model = CurrentActivityViewModel(
        eventRepository: events,
        definitionRepository: definitions,
        switchingService: ActivitySwitchingService(repository: events, clock: clock),
        rankingService: DeterministicActivityRankingService(),
        clock: clock,
        onActivityChanged: { notifications += 1 }
    )

    await model.load()
    await model.select(lunch)
    await model.undo()

    #expect(notifications == 2)
}
