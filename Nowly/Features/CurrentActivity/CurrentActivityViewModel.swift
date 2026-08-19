import Foundation
import Observation

@MainActor
@Observable
final class CurrentActivityViewModel {
    private let eventRepository: any ActivityEventRepository
    private let definitionRepository: any ActivityDefinitionRepository
    private let switchingService: ActivitySwitchingService
    private let rankingService: any ActivityRankingService
    private let clock: any Clock
    private let onActivityChanged: (() -> Void)?

    private(set) var currentActivity: ActivityDefinition?
    private(set) var suggestions: [RankedActivity] = []
    private(set) var canUndo = false
    private(set) var errorMessage: String?
    private(set) var selectionFeedbackID = UUID()
    private var lastReceipt: SwitchReceipt?

    init(
        eventRepository: any ActivityEventRepository,
        definitionRepository: any ActivityDefinitionRepository,
        switchingService: ActivitySwitchingService,
        rankingService: any ActivityRankingService = DeterministicActivityRankingService(),
        clock: any Clock = SystemClock(),
        onActivityChanged: (() -> Void)? = nil
    ) {
        self.eventRepository = eventRepository
        self.definitionRepository = definitionRepository
        self.switchingService = switchingService
        self.rankingService = rankingService
        self.clock = clock
        self.onActivityChanged = onActivityChanged
    }

    func load() async {
        do {
            let activeEvent = try await eventRepository.activeEvent()
            if let activeEvent {
                currentActivity = try await definitionRepository.definition(id: activeEvent.activityDefinitionID)
            } else {
                currentActivity = nil
            }
            let definitions = try await definitionRepository.allDefinitions()
            let context = ActivityContext(
                now: clock.now,
                timeZone: .current,
                currentActivityID: nil,
                previousActivityID: nil,
                usage: [:]
            )
            suggestions = rankingService.rank(
                activities: definitions.filter { $0.isFavorite && !$0.isArchived },
                context: context,
                limit: .max
            )
            errorMessage = nil
        } catch {
            errorMessage = "Не удалось загрузить активности."
        }
    }

    func select(_ activity: ActivityDefinition) async {
        do {
            let receipt = try await switchingService.switchActivity(to: activity.id, source: .app)
            lastReceipt = receipt
            canUndo = receipt.isUndoable
            if receipt != .noChange {
                selectionFeedbackID = UUID()
            }
            await load()
            if receipt != .noChange {
                onActivityChanged?()
            }
        } catch {
            errorMessage = "Не удалось сохранить активность."
        }
    }

    func undo() async {
        guard let lastReceipt else { return }
        do {
            try await switchingService.undo(lastReceipt)
            self.lastReceipt = nil
            canUndo = false
            await load()
            onActivityChanged?()
        } catch {
            errorMessage = "Не удалось отменить действие."
        }
    }

    func toggleFavorite(_ activity: ActivityDefinition) async {
        do {
            let updated = ActivityDefinition(
                id: activity.id,
                name: activity.name,
                parentID: activity.parentID,
                icon: activity.icon,
                isFavorite: !activity.isFavorite,
                isArchived: activity.isArchived,
                sortOrder: activity.sortOrder,
                createdAt: activity.createdAt
            )
            try await definitionRepository.save(updated)
            await load()
        } catch {
            errorMessage = "Не удалось обновить избранное."
        }
    }
}
