import Foundation

struct ActivityHierarchySelection: Equatable {
    let baseActivityID: UUID
    let refinementActivityID: UUID?

    static func resolve(selectedActivityID: UUID, definitions: [ActivityDefinition]) -> ActivityHierarchySelection {
        let definitionsByID = Dictionary(uniqueKeysWithValues: definitions.map { ($0.id, $0) })
        guard var activity = definitionsByID[selectedActivityID] else {
            return ActivityHierarchySelection(baseActivityID: selectedActivityID, refinementActivityID: nil)
        }

        var visited = Set<UUID>()
        while let parentID = activity.parentID,
              visited.insert(activity.id).inserted,
              let parent = definitionsByID[parentID] {
            activity = parent
        }

        return ActivityHierarchySelection(
            baseActivityID: activity.id,
            refinementActivityID: activity.id == selectedActivityID ? nil : selectedActivityID
        )
    }
}
