import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: Settings

    private let columns = [GridItem(.adaptive(minimum: 44), spacing: 14)]

    var body: some View {
        Form {
            Section {
                labeledField(icon: "ellipsis.curlybraces", tint: .indigo,
                             title: "User-Agent", placeholder: "Happ/1.0",
                             text: $settings.userAgent)
                labeledField(icon: "iphone", tint: .teal,
                             title: "X-HWID", placeholder: "device id",
                             text: $settings.hwid)
            } header: {
                Text("Идентификация")
            } footer: {
                Text("Эти заголовки отправляются на sub URL. Без правильных значений сервер отклоняет запрос.")
            }

            Section("Оформление") {
                accentPicker
                Picker("Тема", selection: $settings.appearance) {
                    ForEach(AppAppearance.allCases) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section {
                Toggle("Уведомления об обновлениях", isOn: $settings.notificationsEnabled)
                    .onChange(of: settings.notificationsEnabled) { enabled in
                        if enabled {
                            Task { await NotificationService().requestAuthorization() }
                        }
                    }
            } header: {
                Text("Обновления")
            } footer: {
                Text("Подписки обновляются при открытии приложения и по pull-to-refresh. Если набор конфигов изменился — придёт уведомление.")
            }

            Section {
                NavigationLink {
                    AboutView()
                } label: {
                    Label("О happwn", systemImage: "info.circle")
                }
                Link(destination: URL(string: "https://github.com/useruserdev/happwn")!) {
                    Label("Исходники на GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
                }
            }
        }
        .navigationTitle("Настройки")
    }

    private func labeledField(icon: String, tint: Color, title: String,
                              placeholder: String, text: Binding<String>) -> some View {
        HStack(spacing: 12) {
            IconBadge(systemName: icon, color: tint)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.caption).foregroundStyle(.secondary)
                TextField(placeholder, text: text)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }
        }
    }

    private var accentPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Акцентный цвет").font(.callout)
            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(AppAccent.allCases) { accent in
                    Circle()
                        .fill(accent.color)
                        .frame(width: 32, height: 32)
                        .overlay {
                            if settings.accent == accent {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                        .overlay {
                            Circle()
                                .strokeBorder(Color.primary.opacity(settings.accent == accent ? 0.25 : 0), lineWidth: 2)
                                .padding(-3)
                        }
                        .contentShape(Circle())
                        .onTapGesture {
                            settings.accent = accent
                            Haptics.tap()
                        }
                        .accessibilityLabel(accent.rawValue)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
