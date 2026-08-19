import Foundation
import Testing
@testable import Nowly

@Test func aggregationCountsOnlyThePartOfEventInsideDay() throws {
    let calendar = Calendar(identifier: .gregorian)
    let timeZone = TimeZone(identifier: "Europe/Moscow")!
    let start = try #require(calendar.date(from: DateComponents(timeZone: timeZone, year: 2026, month: 8, day: 19, hour: 23, minute: 30)))
    let end = try #require(calendar.date(from: DateComponents(timeZone: timeZone, year: 2026, month: 8, day: 20, hour: 7, minute: 30)))
    let sleepID = UUID()
    let event = try ActivityEvent(activityDefinitionID: sleepID, startDate: start, endDate: end, source: .app)

    let result = DailyAggregationService(clock: FixedClock(now: end)).aggregate(
        events: [event],
        day: start,
        timeZone: timeZone
    )

    #expect(result.totalTracked == 30 * 60)
    #expect(result.durationsByActivity[sleepID] == 30 * 60)
}
