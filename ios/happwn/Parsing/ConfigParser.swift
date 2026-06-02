import Foundation

enum ConfigParser {
    static let knownSchemes: Set<String> = [
        "vless", "vmess", "trojan", "ss", "ssr",
        "hysteria", "hysteria2", "hy2", "tuic", "wireguard",
    ]

    /// Parse a subscription body (base64-wrapped or plain) into config entries.
    static func parse(_ body: Data) -> [ConfigEntry] {
        extract(from: decodeBody(body))
    }

    /// Decode the body: if the whole thing is base64 of a config list, return that;
    /// otherwise return the raw UTF-8 text.
    static func decodeBody(_ body: Data) -> String {
        let raw = String(data: body, encoding: .utf8) ?? ""
        let compact = raw.components(separatedBy: .whitespacesAndNewlines).joined()
        if let decoded = base64Decode(compact),
           let text = String(data: decoded, encoding: .utf8),
           containsKnownScheme(text) {
            return text
        }
        return raw
    }

    private static func extract(from text: String) -> [ConfigEntry] {
        text
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { line in
                guard let colon = line.firstIndex(of: ":") else { return false }
                return knownSchemes.contains(String(line[..<colon]).lowercased())
            }
            .map { ConfigEntry(uri: $0) }
    }

    private static func containsKnownScheme(_ text: String) -> Bool {
        knownSchemes.contains { text.contains("\($0)://") }
    }

    private static func base64Decode(_ s: String) -> Data? {
        var t = s.replacingOccurrences(of: "-", with: "+")
                 .replacingOccurrences(of: "_", with: "/")
        while t.count % 4 != 0 { t.append("=") }
        return Data(base64Encoded: t)
    }
}
