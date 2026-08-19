import AppIntents
import Foundation
import WidgetKit

struct SwitchActivityIntent: AppIntent {
    static let title: LocalizedStringResource = "Переключить активность"
    static let openAppWhenRun = false

    @Parameter(title: "Активность") var activityID: String

    init() {
        self.activityID = ""
    }

    init(activityID: UUID) {
        self.activityID = activityID.uuidString
    }

    func perform() async throws -> some IntentResult {
        let dependencies = await MainActor.run { AppDependencies.production() }
        _ = try await Self.switchActivity(
            idString: activityID,
            definitionRepository: dependencies.repository,
            switchingService: dependencies.switchingService
        )
        WidgetCenter.shared.reloadTimelines(ofKind: "ActivityWidget")
        return .result()
    }

    @discardableResult
    static func switchActivity(
        idString: String,
        definitionRepository: any ActivityDefinitionRepository,
        switchingService: ActivitySwitchingService
    ) async throws -> SwitchReceipt {
        guard let id = UUID(uuidString: idString),
              let definition = try await definitionRepository.definition(id: id),
              !definition.isArchived else {
            return .noChange
        }
        return try await switchingService.switchActivity(to: id, source: .widget)
    }
}
