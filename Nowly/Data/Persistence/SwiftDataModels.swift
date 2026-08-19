import Foundation
import SwiftData

@Model
final class StoredActivityDefinition {
    @Attribute(.unique) var id: UUID
    var name: String
    var localizationKey: String?
    var parentID: UUID?
    var icon: String?
    var isFavorite: Bool
    var isArchived: Bool
    var sortOrder: Int
    var createdAt: Date

    init(_ definition: ActivityDefinition) {
        id = definition.id
        name = definition.name
        localizationKey = definition.localizationKey
        parentID = definition.parentID
        icon = definition.icon
        isFavorite = definition.isFavorite
        isArchived = definition.isArchived
        sortOrder = definition.sortOrder
        createdAt = definition.createdAt
    }

    var domainValue: ActivityDefinition {
        ActivityDefinition(
            id: id,
            name: name,
            localizationKey: localizationKey,
            parentID: parentID,
            icon: icon,
            isFavorite: isFavorite,
            isArchived: isArchived,
            sortOrder: sortOrder,
            createdAt: createdAt
        )
    }

    func update(from definition: ActivityDefinition) {
        name = definition.name
        localizationKey = definition.localizationKey
        parentID = definition.parentID
        icon = definition.icon
        isFavorite = definition.isFavorite
        isArchived = definition.isArchived
        sortOrder = definition.sortOrder
        createdAt = definition.createdAt
    }
}

@Model
final class StoredActivityEvent {
    @Attribute(.unique) var id: UUID
    var activityDefinitionID: UUID
    var startDate: Date
    var endDate: Date?
    var createdAt: Date
    var updatedAt: Date
    var note: String?
    var sourceRawValue: String

    init(_ event: ActivityEvent) {
        id = event.id
        activityDefinitionID = event.activityDefinitionID
        startDate = event.startDate
        endDate = event.endDate
        createdAt = event.createdAt
        updatedAt = event.updatedAt
        note = event.note
        sourceRawValue = event.source.rawValue
    }

    var domainValue: ActivityEvent? {
        try? ActivityEvent(
            id: id,
            activityDefinitionID: activityDefinitionID,
            startDate: startDate,
            endDate: endDate,
            createdAt: createdAt,
            updatedAt: updatedAt,
            note: note,
            source: ActivitySource(rawValue: sourceRawValue) ?? .other
        )
    }

    func update(from event: ActivityEvent) {
        activityDefinitionID = event.activityDefinitionID
        startDate = event.startDate
        endDate = event.endDate
        createdAt = event.createdAt
        updatedAt = event.updatedAt
        note = event.note
        sourceRawValue = event.source.rawValue
    }
}
