import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct ActivityHistoryExport: Encodable {
    struct Event: Encodable {
        let id: UUID
        let activityID: UUID
        let activityName: String
        let startDate: Date
        let endDate: Date?
        let createdAt: Date
        let updatedAt: Date
        let note: String?
        let source: String
    }

    let exportedAt: Date
    let events: [Event]

    init(events: [ActivityEvent], activityNames: [UUID: String], exportedAt: Date = .now) {
        self.exportedAt = exportedAt
        self.events = events.map { event in
            Event(
                id: event.id,
                activityID: event.activityDefinitionID,
                activityName: activityNames[event.activityDefinitionID] ?? "Неизвестная активность",
                startDate: event.startDate,
                endDate: event.endDate,
                createdAt: event.createdAt,
                updatedAt: event.updatedAt,
                note: event.note,
                source: event.source.rawValue
            )
        }
    }

    func encodedData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(self)
    }
}

struct ActivityHistoryExportDocument: FileDocument {
    static let readableContentTypes: [UTType] = [.json]

    let data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
