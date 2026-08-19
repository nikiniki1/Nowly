import Foundation

enum SwitchReceipt: Equatable, Sendable {
    case createdFirst(newEvent: ActivityEvent)
    case switched(previous: ActivityEvent, newEvent: ActivityEvent)
    case noChange

    var isUndoable: Bool {
        self != .noChange
    }
}

actor ActivitySwitchingService {
    private let repository: any ActivityEventRepository
    private let clock: any Clock

    init(repository: any ActivityEventRepository, clock: any Clock) {
        self.repository = repository
        self.clock = clock
    }

    func switchActivity(to activityDefinitionID: UUID, source: ActivitySource) async throws -> SwitchReceipt {
        let now = clock.now

        guard let activeEvent = try await repository.activeEvent() else {
            let newEvent = try ActivityEvent(
                activityDefinitionID: activityDefinitionID,
                startDate: now,
                endDate: nil,
                createdAt: now,
                updatedAt: now,
                source: source
            )
            try await repository.save(newEvent)
            return .createdFirst(newEvent: newEvent)
        }

        guard activeEvent.activityDefinitionID != activityDefinitionID else {
            return .noChange
        }

        let closedEvent = try ActivityEvent(
            id: activeEvent.id,
            activityDefinitionID: activeEvent.activityDefinitionID,
            startDate: activeEvent.startDate,
            endDate: now,
            createdAt: activeEvent.createdAt,
            updatedAt: now,
            note: activeEvent.note,
            source: activeEvent.source
        )
        let newEvent = try ActivityEvent(
            activityDefinitionID: activityDefinitionID,
            startDate: now,
            endDate: nil,
            createdAt: now,
            updatedAt: now,
            source: source
        )

        try await repository.save(closedEvent)
        do {
            try await repository.save(newEvent)
        } catch {
            try await repository.save(activeEvent)
            throw error
        }

        return .switched(previous: activeEvent, newEvent: newEvent)
    }

    func undo(_ receipt: SwitchReceipt) async throws {
        switch receipt {
        case let .createdFirst(newEvent):
            try await repository.delete(id: newEvent.id)
        case let .switched(previous, newEvent):
            try await repository.delete(id: newEvent.id)
            try await repository.save(previous)
        case .noChange:
            break
        }
    }
}
