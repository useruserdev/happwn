import Foundation

struct ExtractionService {
    /// Injectable for testing; defaults to the real FFI + network.
    var decryptLink: (String) throws -> DecryptResult = HappCrypto.decrypt
    var client: SubscriptionClient = SubscriptionClient()

    func run(link: String, userAgent: String, hwid: String) async throws -> ExtractionResult {
        let decrypted = try decryptLink(link)
        let value = decrypted.value.trimmingCharacters(in: .whitespacesAndNewlines)

        if value.hasPrefix("http://") || value.hasPrefix("https://") {
            let data = try await client.fetch(urlString: value, userAgent: userAgent, hwid: hwid)
            let configs = ConfigParser.parse(data)
            return ExtractionResult(
                mode: decrypted.mode,
                source: value,
                configs: configs,
                rawBody: configs.isEmpty ? String(data: data, encoding: .utf8) : nil
            )
        } else {
            let configs = ConfigParser.parse(Data(value.utf8))
            return ExtractionResult(
                mode: decrypted.mode,
                source: "(inline)",
                configs: configs,
                rawBody: configs.isEmpty ? value : nil
            )
        }
    }
}
