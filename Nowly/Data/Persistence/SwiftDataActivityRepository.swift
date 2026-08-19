import Foundation
import SwiftData

@ModelActor
actor SwiftDataActivityRepository: ActivityEventRepository, ActivityDefinitionRepository {
    enum RepositoryError: Error, Equatable, Sendable {
        case multipleActiveEvents
    }

    func event(id: UUID) throws -> ActivityEvent? {
        try storedEvents().first { $0.id == id }?.domainValue
    }

    func activeEvent() throws -> ActivityEvent? {
        try storedEvents()
            .filter { $0.endDate == nil }
            .sorted(by: Self.sortStoredEvents)
            .first?
            .domainValue
    }

    func events(in interval: DateInterval) throws -> [ActivityEvent] {
        try storedEvents()
            .filter { storedEvent in
                let eventEnd = storedEvent.endDate ?? .distantFuture
                return storedEvent.startDate < interval.end && eventEnd > interval.start
            }
            .compactMap(\.domainValue)
            .sorted(by: Self.sortEvents)
    }

    func save(_ event: ActivityEvent) throws {
        let existing = try storedEvents()
        if event.endDate == nil,
           existing.contains(where: { $0.id != event.id && $0.endDate == nil }) {
            throw RepositoryError.multipleActiveEvents
        }

        if let stored = existing.first(where: { $0.id == event.id }) {
            stored.update(from: event)
        } else {
            modelContext.insert(StoredActivityEvent(event))
        }
        try modelContext.save()
    }

    func delete(id: UUID) throws {
        if let stored = try storedEvents().first(where: { $0.id == id }) {
            modelContext.delete(stored)
            try modelContext.save()
        }
    }

    func deleteEvents(in interval: DateInterval? = nil) throws -> Int {
        let matching = try storedEvents().filter { event in
            guard let interval else { return true }
            let eventEnd = event.endDate ?? .distantFuture
            return event.startDate < interval.end && eventEnd > interval.start
        }
        matching.forEach(modelContext.delete)
        if !matching.isEmpty {
            try modelContext.save()
        }
        return matching.count
    }

    func definition(id: UUID) throws -> ActivityDefinition? {
        try storedDefinitions().first { $0.id == id }?.domainValue
    }

    func allDefinitions() throws -> [ActivityDefinition] {
        try storedDefinitions().map(\.domainValue).sorted(by: Self.sortDefinitions)
    }

    func topLevelDefinitions() throws -> [ActivityDefinition] {
        try storedDefinitions()
            .filter { $0.parentID == nil && !$0.isArchived }
            .map(\.domainValue)
            .sorted(by: Self.sortDefinitions)
    }

    func children(of parentID: UUID) throws -> [ActivityDefinition] {
        try storedDefinitions()
            .filter { $0.parentID == parentID && !$0.isArchived }
            .map(\.domainValue)
            .sorted(by: Self.sortDefinitions)
    }

    func save(_ definition: ActivityDefinition) throws {
        let existing = try storedDefinitions()
        if let stored = existing.first(where: { $0.id == definition.id }) {
            stored.update(from: definition)
        } else {
            modelContext.insert(StoredActivityDefinition(definition))
        }
        try modelContext.save()
    }

    func seedInitialDefinitions() throws {
        let existing = Dictionary(uniqueKeysWithValues: try storedDefinitions().map { ($0.id, $0) })
        for definition in InitialActivitySeed.definitions {
            if existing[definition.id] == nil {
                modelContext.insert(StoredActivityDefinition(definition))
            }
        }
        try modelContext.save()
    }

    private func storedEvents() throws -> [StoredActivityEvent] {
        try modelContext.fetch(FetchDescriptor<StoredActivityEvent>())
    }

    private func storedDefinitions() throws -> [StoredActivityDefinition] {
        try modelContext.fetch(FetchDescriptor<StoredActivityDefinition>())
    }

    nonisolated private static func sortEvents(_ lhs: ActivityEvent, _ rhs: ActivityEvent) -> Bool {
        if lhs.startDate != rhs.startDate { return lhs.startDate < rhs.startDate }
        return lhs.id.uuidString < rhs.id.uuidString
    }

    nonisolated private static func sortStoredEvents(_ lhs: StoredActivityEvent, _ rhs: StoredActivityEvent) -> Bool {
        if lhs.startDate != rhs.startDate { return lhs.startDate < rhs.startDate }
        return lhs.id.uuidString < rhs.id.uuidString
    }

    nonisolated private static func sortDefinitions(_ lhs: ActivityDefinition, _ rhs: ActivityDefinition) -> Bool {
        if lhs.sortOrder != rhs.sortOrder { return lhs.sortOrder < rhs.sortOrder }
        return lhs.id.uuidString < rhs.id.uuidString
    }
}
