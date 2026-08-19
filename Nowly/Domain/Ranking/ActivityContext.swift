import Foundation

struct ActivityUsageStatistics: Sendable, Equatable {
    let totalCount: Int
    let lastUsedAt: Date?
    let hourCount: Int
    let weekdayCount: Int
    let transitionCount: Int
}

struct ActivityContext: Sendable {
    let now: Date
    let timeZone: TimeZone
    let currentActivityID: UUID?
    let previousActivityID: UUID?
    let usage: [UUID: ActivityUsageStatistics]
}
