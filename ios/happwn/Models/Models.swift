import Foundation

struct ConfigEntry: Identifiable, Equatable {
    let id = UUID()
    let uri: String

    var scheme: String {
        String(uri.prefix(while: { $0 != ":" })).lowercased()
    }

    /// Server address (IP or domain) extracted from the config, when determinable.
    /// Handles the `scheme://[userinfo@]host:port` form (vless, trojan, ss…) and
    /// the base64-JSON form (vmess, "add" field).
    var host: String? {
        if scheme == "vmess" { return vmessHost() }
        return authorityHost()
    }

    private func vmessHost() -> String? {
        let payload = String(uri.dropFirst("vmess://".count))
        guard let data = Self.base64Decode(payload),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let add = obj["add"] as? String, !add.isEmpty else { return nil }
        return add
    }

    private func authorityHost() -> String? {
        guard let r = uri.range(of: "://") else { return nil }
        var authority = uri[r.upperBound...]
        if let cut = authority.firstIndex(where: { $0 == "/" || $0 == "?" || $0 == "#" }) {
            authority = authority[..<cut]
        }
        if let at = authority.lastIndex(of: "@") {
            authority = authority[authority.index(after: at)...]
        }
        let s = String(authority)
        if s.hasPrefix("["), let close = s.firstIndex(of: "]") { // IPv6 literal
            return String(s[s.index(after: s.startIndex)..<close])
        }
        let h = s.prefix { $0 != ":" }
        return h.isEmpty ? nil : String(h)
    }

    private static func base64Decode(_ s: String) -> Data? {
        var t = s.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        while t.count % 4 != 0 { t.append("=") }
        return Data(base64Encoded: t)
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
