import Foundation

struct RankedActivity: Sendable, Equatable {
    let activity: ActivityDefinition
    let score: Int
}

protocol ActivityRankingService: Sendable {
    func rank(activities: [ActivityDefinition], context: ActivityContext, limit: Int) -> [RankedActivity]
}

struct DeterministicActivityRankingService: ActivityRankingService {
    private enum Score {
        static let favorite = 1_000
        static let totalCount = 10
        static let hour = 8
        static let weekday = 5
        static let transition = 12
        static let morning = ["Сон": 300, "Завтрак": 200, "Дорога": 100, "Работа": 50]
        static let midday = ["Обед": 300, "Работа": 200, "Прогулка": 100]
        static let evening = ["Ужин": 300, "Зал": 200, "Прогулка": 100, "Отдых": 50]
    }

    func rank(activities: [ActivityDefinition], context: ActivityContext, limit: Int) -> [RankedActivity] {
        let coldStartScores = context.usage.isEmpty ? Self.coldStartScores(at: context.now, timeZone: context.timeZone) : [:]

        return activities
            .filter { !$0.isArchived && $0.id != context.currentActivityID }
            .map { activity in
                let usage = context.usage[activity.id]
                let recency = usage?.lastUsedAt.map { max(0, 100 - Int(context.now.timeIntervalSince($0) / 60)) } ?? 0
                let score = (activity.isFavorite ? Score.favorite : 0)
                    + (usage?.totalCount ?? 0) * Score.totalCount
                    + recency
                    + (usage?.hourCount ?? 0) * Score.hour
                    + (usage?.weekdayCount ?? 0) * Score.weekday
                    + (usage?.transitionCount ?? 0) * Score.transition
                    + (coldStartScores[activity.name] ?? 0)
                return RankedActivity(activity: activity, score: score)
            }
            .sorted { lhs, rhs in
                if lhs.score != rhs.score { return lhs.score > rhs.score }
                if lhs.activity.sortOrder != rhs.activity.sortOrder { return lhs.activity.sortOrder < rhs.activity.sortOrder }
                return lhs.activity.id.uuidString < rhs.activity.id.uuidString
            }
            .prefix(max(0, limit))
            .map { $0 }
    }

    private static func coldStartScores(at date: Date, timeZone: TimeZone) -> [String: Int] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        return switch calendar.component(.hour, from: date) {
        case 5...10:
            Score.morning
        case 11...16:
            Score.midday
        default:
            Score.evening
        }
    }
}
