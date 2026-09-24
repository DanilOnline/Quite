import SwiftUI
import WidgetKit

struct LauncherItem: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String
    var destination: String
    var shortcut: Bool = true
    var url: URL? {
        if shortcut {
            var parts = URLComponents()
            parts.scheme = "shortcuts"
            parts.host = "run-shortcut"
            parts.queryItems = [URLQueryItem(name: "name", value: destination)]
            return parts.url
        }
        guard let value = URL(string: destination), let scheme = value.scheme,
              !["file", "javascript", "data", "quiet"].contains(scheme.lowercased()) else { return nil }
        return value
    }
    var route: URL { URL(string: "quiet://launch/\(id.uuidString)")! }
}
struct LauncherSettings: Codable, Equatable {
    var items = ["Phone", "Messages", "Maps", "Music", "Camera", "Notes"].map {
        LauncherItem(name: $0.lowercased(), destination: "Quiet \($0)")
    }
    var theme = "dark"
    var fontSize = 27.0
    var bold = false
    var italic = false
    var centered = false
    var scheme: ColorScheme? { theme == "auto" ? nil : (theme == "dark" ? .dark : .light) }
}
enum LauncherStorage {
    static var defaults: UserDefaults {
        let group = Bundle.main.object(forInfoDictionaryKey: "SharedAppGroup") as? String ?? "group.com.example.quiet"
        return UserDefaults(suiteName: group)!
    }
    static func load() -> LauncherSettings {
        guard let data = defaults.data(forKey: "launcher"),
              let value = try? JSONDecoder().decode(LauncherSettings.self, from: data) else { return LauncherSettings() }
        return value
    }
    static func save(_ value: LauncherSettings) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        defaults.set(data, forKey: "launcher")
        WidgetCenter.shared.reloadAllTimelines()
    }
}
struct LauncherList: View {
    let settings: LauncherSettings
    let limit: Int
    @Environment(\.colorScheme) private var systemScheme
    var dark: Bool { (settings.scheme ?? systemScheme) == .dark }
    var body: some View {
        VStack(alignment: settings.centered ? .center : .leading, spacing: 0) {
            ForEach(Array(settings.items.prefix(limit))) { item in
                Link(destination: item.route) {
                    Text(item.name)
                        .font(.system(size: settings.fontSize, weight: settings.bold ? .bold : .regular))
                        .italic(settings.italic)
                        .lineLimit(1).minimumScaleFactor(0.6)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: settings.centered ? .center : .leading)
                        .contentShape(Rectangle())
                }.buttonStyle(.plain)
            }
            if settings.items.isEmpty { Text("Додайте застосунки в Quiet").font(.body) }
        }
        .foregroundStyle(dark ? Color.white : Color.black)
    }
}
