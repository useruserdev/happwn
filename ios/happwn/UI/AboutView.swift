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
            VStack(spacing: 16) {
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 112, height: 112)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                    .padding(.top, 24)

                VStack(spacing: 4) {
                    Text("happwn").font(.largeTitle.bold())
                    Text(version).font(.subheadline).foregroundColor(.secondary)
                    Text("Happ subscription config extractor")
                        .font(.callout).foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(alignment: .leading, spacing: 12) {
                    section(
                        "What it does",
                        "Paste a happ:// link — happwn decrypts it, follows the embedded "
                        + "subscription URL with your User-Agent and X-HWID, and extracts every "
                        + "config (vless, vmess, trojan, ss, …) for copy and export."
                    )
                    section(
                        "Schemes",
                        "crypt, crypt2, crypt3, crypt4 (RSA PKCS#1 v1.5) and crypt5 "
                        + "(RSA → ChaCha20-Poly1305). Decryption runs fully on-device."
                    )
                    section(
                        "Privacy",
                        "No analytics, no servers of our own. Requests go only to the "
                        + "subscription URL contained in your link."
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                Link(destination: repoURL) {
                    Label("Source on GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Text("Apache-2.0")
                    .font(.footnote).foregroundColor(.secondary)
                    .padding(.bottom, 24)
            }
            .padding(.horizontal)
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func section(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.headline)
            Text(body).font(.callout).foregroundColor(.secondary)
        }
    }
}
