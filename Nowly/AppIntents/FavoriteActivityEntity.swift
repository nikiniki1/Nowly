import AppIntents
import Foundation

struct FavoriteActivityEntity: AppEntity, Identifiable {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Избранная активность"
    static let defaultQuery = FavoriteActivityEntityQuery()

    let id: UUID
    let name: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

struct FavoriteActivityEntityQuery: EntityQuery {
    func entities(for identifiers: [UUID]) async throws -> [FavoriteActivityEntity] {
        let repository = await MainActor.run { AppDependencies.production().repository }
        var result: [FavoriteActivityEntity] = []
        for id in identifiers {
            guard let activity = try await repository.definition(id: id), activity.isFavorite, !activity.isArchived else { continue }
            result.append(FavoriteActivityEntity(id: activity.id, name: activity.displayName))
        }
        return result
    }

    func suggestedEntities() async throws -> [FavoriteActivityEntity] {
        let repository = await MainActor.run { AppDependencies.production().repository }
        return try await repository.allDefinitions()
            .filter { $0.isFavorite && !$0.isArchived }
            .map { FavoriteActivityEntity(id: $0.id, name: $0.displayName) }
    }
}
