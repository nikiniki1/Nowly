import SwiftUI
import WidgetKit

struct ActivityWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: CurrentActivitySnapshot
}

struct ActivityTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> ActivityWidgetEntry {
        ActivityWidgetEntry(date: Date(), snapshot: CurrentActivitySnapshot(currentActivity: nil, currentStartedAt: nil, suggestions: []))
    }

    func getSnapshot(in context: Context, completion: @escaping @Sendable (ActivityWidgetEntry) -> Void) {
        let limit = suggestionLimit(for: context.family)
        Task {
            completion(await makeEntry(limit: limit))
        }
    }

    func getTimeline(in context: Context, completion: @escaping @Sendable (Timeline<ActivityWidgetEntry>) -> Void) {
        let limit = suggestionLimit(for: context.family)
        Task {
            let entry = await makeEntry(limit: limit)
            let reloadDate = entry.date.addingTimeInterval(30 * 60)
            completion(Timeline(entries: [entry], policy: .after(reloadDate)))
        }
    }

    private func suggestionLimit(for family: WidgetFamily) -> Int {
        switch family {
        case .systemSmall: 2
        default: 4
        }
    }

    private func makeEntry(limit: Int) async -> ActivityWidgetEntry {
        let now = Date()
        guard let container = try? ActivityModelContainer.make() else {
            return ActivityWidgetEntry(date: now, snapshot: CurrentActivitySnapshot(currentActivity: nil, currentStartedAt: nil, suggestions: []))
        }
        let repository = SwiftDataActivityRepository(modelContainer: container)
        let snapshot = try? await CurrentActivitySnapshotBuilder.make(
            eventRepository: repository,
            definitionRepository: repository,
            now: now,
            suggestionLimit: limit
        )
        return ActivityWidgetEntry(
            date: now,
            snapshot: snapshot ?? CurrentActivitySnapshot(currentActivity: nil, currentStartedAt: nil, suggestions: [])
        )
    }
}
