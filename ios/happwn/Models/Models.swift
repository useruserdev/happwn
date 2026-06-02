import Foundation

struct ConfigEntry: Identifiable, Equatable {
    let id = UUID()
    let uri: String

    var scheme: String {
        String(uri.prefix(while: { $0 != ":" })).lowercased()
    }

    static func == (lhs: ConfigEntry, rhs: ConfigEntry) -> Bool {
        lhs.uri == rhs.uri
    }
}

struct ExtractionResult {
    let mode: String
    let source: String
    let configs: [ConfigEntry]
    /// Set when nothing parsed, so the UI can show the raw body for inspection.
    let rawBody: String?
}
