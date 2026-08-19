import Foundation
import Observation

@MainActor
@Observable
final class TimelineViewModel {
    private let eventRepository: any ActivityEventRepository
    private let editor: TimelineEditor
    let day: Date
    private let calendar: Calendar

    private(set) var events: [ActivityEvent] = []
    private(set) var errorMessage: String?

    init(eventRepository: any ActivityEventRepository, day: Date = .now, timeZone: TimeZone = .current) {
        self.eventRepository = eventRepository
        editor = TimelineEditor(repository: eventRepository)
        self.day = day
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        self.calendar = calendar
    }

    func load() async {
        do {
            events = try await eventRepository.events(in: dayInterval)
            errorMessage = nil
        } catch {
            errorMessage = "Не удалось загрузить таймлайн."
        }
    }

    func save(_ event: ActivityEvent) async throws {
        try await editor.update(event)
        await load()
    }

    func delete(eventID: UUID) async throws {
        try await editor.delete(id: eventID)
        await load()
    }

    var dayInterval: DateInterval {
        calendar.dateInterval(of: .day, for: day)!
    }
}
