import Foundation
import Testing
@testable import Nowly

@Test func historyExportIncludesActivityNameAndISO8601Dates() throws {
    let activityID = UUID()
    let event = try ActivityEvent(
        id: UUID(),
        activityDefinitionID: activityID,
        startDate: Date(timeIntervalSinceReferenceDate: 0),
        endDate: Date(timeIntervalSinceReferenceDate: 60),
        note: "Фокус",
        source: .app
    )

    let data = try ActivityHistoryExport(events: [event], activityNames: [activityID: "Работа"]).encodedData()
    let payload = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    let events = try #require(payload?["events"] as? [[String: Any]])
    let exportedEvent = try #require(events.first)

    #expect(exportedEvent["activityName"] as? String == "Работа")
    #expect(exportedEvent["note"] as? String == "Фокус")
    #expect(exportedEvent["source"] as? String == "app")
    #expect(exportedEvent["startDate"] as? String == "2001-01-01T00:00:00Z")
}
