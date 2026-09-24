import SwiftUI

@main
struct QuietApp: App {
    @State private var settings = LauncherStorage.load()
    @State private var error: String?
    var body: some Scene {
        WindowGroup {
            ContentView(settings: $settings)
                .preferredColorScheme(settings.scheme)
                .onChange(of: settings) { _, value in LauncherStorage.save(value) }
                .onOpenURL { url in
                    guard url.scheme == "quiet", url.host == "launch" else { return }
                    guard let id = UUID(uuidString: url.lastPathComponent),
                          let item = settings.items.first(where: { $0.id == id }), let target = item.url else {
                        error = "Цей пункт більше не існує або адреса неправильна."; return
                    }
                    UIApplication.shared.open(target, options: [:]) { success in
                        if !success { error = "Не вдалося відкрити застосунок. Перевірте URL або створіть відповідну команду в Shortcuts." }
                    }
                }
                .alert("Не вдалося відкрити", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
                    Button("Зрозуміло") { error = nil }
                } message: { Text(error ?? "") }
        }
    }
}
struct ContentView: View {
    @Binding var settings: LauncherSettings
    @State private var adding = false
    var body: some View {
        NavigationStack {
            Form {
                Section("Попередній перегляд великого віджета") {
                    LauncherList(settings: settings, limit: 8)
                        .padding(22).frame(height: 340)
                        .background(settings.theme == "light" ? Color.white : settings.theme == "dark" ? Color.black : Color(uiColor: .systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                }
                Section {
                    ForEach($settings.items) { $item in
                        NavigationLink { ItemEditor(item: $item) } label: {
                            VStack(alignment: .leading) {
                                Text(item.name)
                                Text(item.shortcut ? "Команда: \(item.destination)" : item.destination)
                                    .font(.caption).foregroundStyle(.secondary).lineLimit(1)
                            }
                        }
                    }
                    .onDelete { settings.items.remove(atOffsets: $0) }
                    .onMove { settings.items.move(fromOffsets: $0, toOffset: $1) }
                    Button("Додати застосунок", systemImage: "plus") { adding = true }
                } header: { Text("Застосунки") } footer: {
                    Text("Середній віджет показує перші 3 пункти, великий — перші 8. Змініть порядок кнопкою Edit.")
                }
                Section("Вигляд") {
                    Picker("Тема", selection: $settings.theme) {
                        Text("Темна").tag("dark"); Text("Світла").tag("light"); Text("Системна").tag("auto")
                    }
                    LabeledContent("Розмір тексту", value: "\(Int(settings.fontSize))")
                    Slider(value: $settings.fontSize, in: 18...36, step: 1)
                    Toggle("Жирний", isOn: $settings.bold)
                    Toggle("Курсив", isOn: $settings.italic)
                    Toggle("По центру", isOn: $settings.centered)
                }
                Section {
                    NavigationLink("Як налаштувати iPhone") { SetupView() }
                }
            }
            .navigationTitle("quiet")
            .toolbar { EditButton() }
            .sheet(isPresented: $adding) {
                AddItemView { settings.items.append($0) }
            }
        }
    }
}
struct ItemEditor: View {
    @Binding var item: LauncherItem
    var body: some View {
        Form {
            TextField("Назва у віджеті", text: $item.name)
            Toggle("Відкрити через Shortcuts", isOn: $item.shortcut)
            TextField(item.shortcut ? "Точна назва команди" : "URL застосунку", text: $item.destination)
                .textInputAutocapitalization(.never).autocorrectionDisabled()
            Text(item.shortcut ? "Створіть команду з такою самою назвою в застосунку «Команди» та додайте дію «Відкрити програму»." : "Введіть URL, який підтримує потрібний застосунок. Якщо адреса невідома, використайте Shortcuts.")
                .font(.footnote).foregroundStyle(.secondary)
        }.navigationTitle("Редагування")
    }
}
struct AddItemView: View {
    var save: (LauncherItem) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var item = LauncherItem(name: "", destination: "")
    var body: some View {
        NavigationStack {
            ItemEditor(item: $item)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Скасувати") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Додати") { save(item); dismiss() }
                            .disabled(item.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || item.destination.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || item.url == nil)
                    }
                }
        }
    }
}
struct SetupView: View {
    var body: some View {
        List {
            Section("1. Команди") {
                Text("Відкрийте «Команди» (Shortcuts). Створіть команду, наприклад Quiet Phone. Додайте дію «Відкрити програму» → «Телефон». Повторіть для інших пунктів. Назва команди має точно збігатися з назвою в налаштуваннях Quiet.")
            }
            Section("2. Віджет") {
                Text("На головному екрані затисніть порожнє місце → редагування → додати віджет → Quiet. Оберіть великий або середній віджет.")
            }
            Section("3. Мінімалістичний екран") {
                Text("Поставте однотонні чорні або білі шпалери відповідно до теми. Приберіть зайві іконки з головного екрана та Dock вручну, залишивши застосунки в Бібліотеці програм.")
            }
            Section("Особливості iOS") {
                Text("Quiet не замінює системний головний екран. iOS визначає відступи, підпис і вигляд віджета. Під час запуску може ненадовго з'являтися Quiet або Shortcuts. Оновлення віджета може відбуватися із затримкою.")
            }
        }.navigationTitle("Налаштування")
    }
}
