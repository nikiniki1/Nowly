import Foundation

struct DailyAggregation: Sendable, Equatable {
    let durationsByActivity: [UUID: TimeInterval]
    let totalTracked: TimeInterval
}

struct DailyAggregationService: Sendable {
    private let clock: any Clock

    init(clock: any Clock) {
        self.clock = clock
    }

    func aggregate(events: [ActivityEvent], day: Date, timeZone: TimeZone) -> DailyAggregation {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let dayStart = calendar.startOfDay(for: day)
        guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else {
            return DailyAggregation(durationsByActivity: [:], totalTracked: 0)
        }

        let dayInterval = DateInterval(start: dayStart, end: dayEnd)
        var durations: [UUID: TimeInterval] = [:]

        for event in events {
            let eventEnd = event.endDate ?? clock.now
            let start = max(event.startDate, dayInterval.start)
            let end = min(eventEnd, dayInterval.end)
            guard end > start else { continue }
            durations[event.activityDefinitionID, default: 0] += end.timeIntervalSince(start)
        }

        return DailyAggregation(
            durationsByActivity: durations,
            totalTracked: durations.values.reduce(0, +)
        )
    }
}
