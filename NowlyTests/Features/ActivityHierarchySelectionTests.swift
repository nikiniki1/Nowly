import Foundation
import Testing
@testable import Nowly

@Test func resolvesRootCategoryForNestedRefinement() {
    let sport = ActivityDefinition(id: UUID(), name: "Sport", parentID: nil, icon: nil, isFavorite: false, isArchived: false, sortOrder: 0, createdAt: .now)
    let gym = ActivityDefinition(id: UUID(), name: "Gym", parentID: sport.id, icon: nil, isFavorite: false, isArchived: false, sortOrder: 0, createdAt: .now)
    let cardio = ActivityDefinition(id: UUID(), name: "Cardio", parentID: gym.id, icon: nil, isFavorite: false, isArchived: false, sortOrder: 0, createdAt: .now)

    let selection = ActivityHierarchySelection.resolve(selectedActivityID: cardio.id, definitions: [sport, gym, cardio])

    #expect(selection.baseActivityID == sport.id)
    #expect(selection.refinementActivityID == cardio.id)
}

@Test func keepsBaseCategoryWithoutRefinement() {
    let work = ActivityDefinition(id: UUID(), name: "Work", parentID: nil, icon: nil, isFavorite: false, isArchived: false, sortOrder: 0, createdAt: .now)

    let selection = ActivityHierarchySelection.resolve(selectedActivityID: work.id, definitions: [work])

    #expect(selection.baseActivityID == work.id)
    #expect(selection.refinementActivityID == nil)
}
