import SwiftUI
import WidgetKit

@main
struct ActivityWidgetBundle: WidgetBundle {
    var body: some Widget {
        ActivityWidget()
    }
}

struct ActivityWidget: Widget {
    private let kind = "ActivityWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ActivityTimelineProvider()) { entry in
            ActivityWidgetView(entry: entry)
        }
        .configurationDisplayName("Текущая активность")
        .description("Быстрый выбор текущей активности.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
