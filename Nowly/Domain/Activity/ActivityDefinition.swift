import Foundation

struct ActivityDefinition: Identifiable, Hashable, Sendable {
    let id: UUID
    let name: String
    let localizationKey: String?
    let parentID: UUID?
    let icon: String?
    let isFavorite: Bool
    let isArchived: Bool
    let sortOrder: Int
    let createdAt: Date

    init(
        id: UUID,
        name: String,
        localizationKey: String? = nil,
        parentID: UUID?,
        icon: String?,
        isFavorite: Bool,
        isArchived: Bool,
        sortOrder: Int,
        createdAt: Date
    ) {
        self.id = id
        self.name = name
        self.localizationKey = localizationKey
        self.parentID = parentID
        self.icon = icon
        self.isFavorite = isFavorite
        self.isArchived = isArchived
        self.sortOrder = sortOrder
        self.createdAt = createdAt
    }

    var displayName: String {
        guard let localizationKey else { return name }
        return Bundle.main.localizedString(forKey: localizationKey, value: name, table: "Localizable")
    }

    func updating(isFavorite: Bool? = nil, isArchived: Bool? = nil) -> ActivityDefinition {
        ActivityDefinition(
            id: id,
            name: name,
            localizationKey: localizationKey,
            parentID: parentID,
            icon: icon,
            isFavorite: isFavorite ?? self.isFavorite,
            isArchived: isArchived ?? self.isArchived,
            sortOrder: sortOrder,
            createdAt: createdAt
        )
    }
}
