import Foundation

protocol ActivityDefinitionRepository: Sendable {
    func definition(id: UUID) async throws -> ActivityDefinition?
    func allDefinitions() async throws -> [ActivityDefinition]
    func topLevelDefinitions() async throws -> [ActivityDefinition]
    func children(of parentID: UUID) async throws -> [ActivityDefinition]
    func save(_ definition: ActivityDefinition) async throws
}

actor InMemoryActivityDefinitionRepository: ActivityDefinitionRepository {
    private var definitionsByID: [UUID: ActivityDefinition] = [:]

    func definition(id: UUID) async throws -> ActivityDefinition? {
        definitionsByID[id]
    }

    func allDefinitions() async throws -> [ActivityDefinition] {
        definitionsByID.values.sorted(by: Self.sort)
    }

    func topLevelDefinitions() async throws -> [ActivityDefinition] {
        definitionsByID.values
            .filter { $0.parentID == nil && !$0.isArchived }
            .sorted(by: Self.sort)
    }

    func children(of parentID: UUID) async throws -> [ActivityDefinition] {
        definitionsByID.values
            .filter { $0.parentID == parentID && !$0.isArchived }
            .sorted(by: Self.sort)
    }

    func save(_ definition: ActivityDefinition) async throws {
        definitionsByID[definition.id] = definition
    }

    nonisolated private static func sort(_ lhs: ActivityDefinition, _ rhs: ActivityDefinition) -> Bool {
        if lhs.sortOrder != rhs.sortOrder {
            return lhs.sortOrder < rhs.sortOrder
        }
        return lhs.id.uuidString < rhs.id.uuidString
    }
}
