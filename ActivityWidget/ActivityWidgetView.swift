import SwiftUI
import WidgetKit

struct ActivityWidgetView: View {
    @Environment(\.widgetFamily) private var family

    let entry: ActivityWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            statusRow
            buttonsGrid
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(for: .widget) {
            Color.clear
        }
    }

    private var statusRow: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let current = entry.snapshot.currentActivity {
                Text(current.displayName)
                    .font(.headline)
                    .lineLimit(1)
                if let startedAt = entry.snapshot.currentStartedAt {
                    Text(startedAt, style: .timer)
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("Время не отслеживается")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var buttonsGrid: some View {
        let suggestions = Array(entry.snapshot.suggestions.prefix(family == .systemSmall ? 2 : 4))
        return HStack(spacing: 8) {
            ForEach(suggestions) { activity in
                Button(intent: SwitchActivityIntent(activityID: activity.id)) {
                    Text(activity.displayName)
                        .font(.caption.weight(.medium))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity, minHeight: 32)
                }
                .buttonStyle(.bordered)
                .tint(.accentColor)
            }
        }
    }
}
