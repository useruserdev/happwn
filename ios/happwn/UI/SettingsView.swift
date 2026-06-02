import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: Settings

    var body: some View {
        Form {
            Section("User-Agent") {
                TextField("Happ/1.0", text: $settings.userAgent)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }
            Section("X-HWID") {
                TextField("device id", text: $settings.hwid)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }
            Section {
                Text("Эти заголовки отправляются на sub URL. Без правильных значений сервер отклоняет запрос.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            Section {
                NavigationLink {
                    AboutView()
                } label: {
                    Label("О приложении", systemImage: "info.circle")
                }
            }
        }
        .navigationTitle("Настройки")
    }
}
