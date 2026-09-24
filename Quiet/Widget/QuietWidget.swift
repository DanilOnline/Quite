import SwiftUI
import WidgetKit

struct QuietEntry: TimelineEntry {
    let date: Date
    let settings: LauncherSettings
}
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> QuietEntry { QuietEntry(date: .now, settings: LauncherSettings()) }
    func getSnapshot(in context: Context, completion: @escaping (QuietEntry) -> Void) {
        completion(QuietEntry(date: .now, settings: LauncherStorage.load()))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<QuietEntry>) -> Void) {
        completion(Timeline(entries: [QuietEntry(date: .now, settings: LauncherStorage.load())], policy: .never))
    }
}
struct QuietWidgetView: View {
    let entry: QuietEntry
    @Environment(\.widgetFamily) private var family
    @Environment(\.colorScheme) private var systemScheme
    var body: some View {
        LauncherList(settings: entry.settings, limit: family == .systemMedium ? 3 : 8)
            .padding(.horizontal, 22).padding(.vertical, 12)
            .containerBackground(for: .widget) {
                (entry.settings.scheme ?? systemScheme) == .dark ? Color.black : Color.white
            }
    }
}
@main
struct QuietWidget: Widget {
    let kind = "QuietWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in QuietWidgetView(entry: entry) }
            .configurationDisplayName("Quiet")
            .description("Ваші застосунки. Тільки текст.")
            .supportedFamilies([.systemMedium, .systemLarge])
            .contentMarginsDisabled()
    }
}
