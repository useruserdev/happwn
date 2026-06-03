import SwiftUI

struct AboutView: View {
    private var version: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "v\(v) (\(b))"
    }

    private let repoURL = URL(string: "https://github.com/useruserdev/happwn")!

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                header

                VStack(alignment: .leading, spacing: 14) {
                    infoCard(
                        "Что делает",
                        "Вставь happ://-ссылку — happwn расшифрует её, перейдёт по встроенному "
                        + "URL подписки с твоими User-Agent и X-HWID и достанет каждый конфиг "
                        + "(vless, vmess, trojan, ss …) для копирования и экспорта."
                    )
                    infoCard(
                        "Схемы",
                        "crypt, crypt2, crypt3, crypt4 (RSA PKCS#1 v1.5) и crypt5 "
                        + "(RSA → ChaCha20-Poly1305). Расшифровка целиком на устройстве."
                    )
                    infoCard(
                        "Приватность",
                        "Без аналитики и собственных серверов. Запросы идут только на URL "
                        + "подписки из твоей ссылки."
                    )
                }

                Link(destination: repoURL) {
                    Label("Source on GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                }
                .buttonStyle(.bordered)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                Text("Apache-2.0")
                    .font(.footnote).foregroundStyle(.secondary)
                    .padding(.bottom, 8)
            }
            .padding(Layout.screenPadding)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("О приложении")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(spacing: 8) {
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 104, height: 104)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: Color.accentColor.opacity(0.35), radius: 14, y: 6)
                .padding(.top, 16)

            Text("happwn").font(.largeTitle.bold())
            Text(version).font(.subheadline).foregroundStyle(.secondary)
            Text("Happ subscription config extractor")
                .font(.callout).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private func infoCard(_ title: String, _ body: String) -> some View {
        GroupedCard {
            VStack(alignment: .leading, spacing: 5) {
                Text(title).font(.headline)
                Text(body).font(.callout).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
        }
    }
}
