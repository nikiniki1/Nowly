import Foundation

enum ActivitySource: String, CaseIterable, Codable, Sendable {
    case app
    case widget
    case control
    case shortcut
    case notification
    case siri
    case healthKit
    case other
}

struct ActivityEvent: Identifiable, Hashable, Sendable {
    enum ValidationError: Error, Equatable, Sendable {
        case invalidInterval
    }

    let id: UUID
    let activityDefinitionID: UUID
    let startDate: Date
    let endDate: Date?
    let createdAt: Date
    let updatedAt: Date
    let note: String?
    let source: ActivitySource

    init(
        id: UUID = UUID(),
        activityDefinitionID: UUID,
        startDate: Date,
        endDate: Date?,
        createdAt: Date? = nil,
        updatedAt: Date? = nil,
        note: String? = nil,
        source: ActivitySource
    ) throws {
        if let endDate, endDate <= startDate {
            throw ValidationError.invalidInterval
        }

        self.id = id
        self.activityDefinitionID = activityDefinitionID
        self.startDate = startDate
        self.endDate = endDate
        self.createdAt = createdAt ?? startDate
        self.updatedAt = updatedAt ?? createdAt ?? startDate
        self.note = note
        self.source = source
    }
}
