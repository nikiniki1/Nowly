import Foundation

protocol ActivityEventRepository: Sendable {
    func event(id: UUID) async throws -> ActivityEvent?
    func activeEvent() async throws -> ActivityEvent?
    func events(in interval: DateInterval) async throws -> [ActivityEvent]
    func save(_ event: ActivityEvent) async throws
    func delete(id: UUID) async throws
    func deleteEvents(in interval: DateInterval?) async throws -> Int
}

actor InMemoryActivityEventRepository: ActivityEventRepository {
    enum RepositoryError: Error, Equatable, Sendable {
        case multipleActiveEvents
    }

    private var eventsByID: [UUID: ActivityEvent] = [:]

    func event(id: UUID) async throws -> ActivityEvent? {
        eventsByID[id]
    }

    func activeEvent() async throws -> ActivityEvent? {
        eventsByID.values.first(where: { $0.endDate == nil })
    }

    func events(in interval: DateInterval) async throws -> [ActivityEvent] {
        eventsByID.values
            .filter { event in
                let eventEnd = event.endDate ?? .distantFuture
                return event.startDate < interval.end && eventEnd > interval.start
            }
            .sorted(by: Self.sort)
    }

    func save(_ event: ActivityEvent) async throws {
        if event.endDate == nil,
           eventsByID.values.contains(where: { $0.id != event.id && $0.endDate == nil }) {
            throw RepositoryError.multipleActiveEvents
        }

        eventsByID[event.id] = event
    }

    func delete(id: UUID) async throws {
        eventsByID[id] = nil
    }

    func deleteEvents(in interval: DateInterval? = nil) async throws -> Int {
        let ids = eventsByID.values.compactMap { event -> UUID? in
            guard let interval else { return event.id }
            let eventEnd = event.endDate ?? .distantFuture
            return event.startDate < interval.end && eventEnd > interval.start ? event.id : nil
        }
        ids.forEach { eventsByID[$0] = nil }
        return ids.count
    }

    nonisolated private static func sort(_ lhs: ActivityEvent, _ rhs: ActivityEvent) -> Bool {
        if lhs.startDate != rhs.startDate {
            return lhs.startDate < rhs.startDate
        }
        return lhs.id.uuidString < rhs.id.uuidString
    }
}
