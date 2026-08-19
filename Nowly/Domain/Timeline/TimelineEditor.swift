import Foundation

struct TimelineEditor: Sendable {
    enum EditError: Error, Equatable, Sendable {
        case overlapsExistingEvent
    }

    private let repository: any ActivityEventRepository

    init(repository: any ActivityEventRepository) {
        self.repository = repository
    }

    func insert(_ event: ActivityEvent) async throws {
        let allEvents = try await repository.events(
            in: DateInterval(start: .distantPast, end: .distantFuture)
        ).filter { $0.id != event.id }

        let leftOverlaps = allEvents.filter {
            $0.startDate < event.startDate && ($0.endDate ?? .distantFuture) > event.startDate
        }
        for existing in leftOverlaps {
            let truncated = try ActivityEvent(
                id: existing.id,
                activityDefinitionID: existing.activityDefinitionID,
                startDate: existing.startDate,
                endDate: event.startDate,
                createdAt: existing.createdAt,
                updatedAt: event.startDate,
                note: existing.note,
                source: existing.source
            )
            try await repository.save(truncated)
        }

        let remaining = try await repository.events(
            in: DateInterval(start: .distantPast, end: .distantFuture)
        ).filter { $0.id != event.id }
        if remaining.contains(where: { existing in
            let existingEnd = existing.endDate ?? .distantFuture
            let eventEnd = event.endDate ?? .distantFuture
            return existing.startDate < eventEnd && existingEnd > event.startDate
        }) {
            throw EditError.overlapsExistingEvent
        }

        try await repository.save(event)
    }

    func update(_ event: ActivityEvent) async throws {
        try await insert(event)
    }

    func delete(id: UUID) async throws {
        try await repository.delete(id: id)
    }
}
