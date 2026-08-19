import Testing
@testable import Nowly

@Test func seedContainsSingleSportRootAndGymHierarchy() throws {
    let sport = try #require(InitialActivitySeed.definitions.first { $0.name == "Спорт" && $0.parentID == nil })
    let gym = try #require(InitialActivitySeed.definitions.first { $0.name == "Зал" && $0.parentID == sport.id })

    #expect(InitialActivitySeed.definitions.filter { $0.name == "Спорт" && $0.parentID == nil }.count == 1)
    #expect(InitialActivitySeed.definitions.contains { $0.name == "Силовая" && $0.parentID == gym.id })
    #expect(sport.localizationKey == "activity.020")
}
