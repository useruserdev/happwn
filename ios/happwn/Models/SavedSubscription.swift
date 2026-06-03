import Foundation

/// A persisted happ:// subscription the user wants to keep and auto-refresh.
struct SavedSubscription: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    /// Original happ:// link; re-decrypted on every refresh.
    var link: String
    /// Snapshot of config URIs from the last successful fetch (for diffing).
    var lastConfigs: [String] = []
    var mode: String? = nil
    /// Last decrypted subscription URL.
    var source: String? = nil
    var lastCheckedAt: Date? = nil
    var lastChangedAt: Date? = nil
    /// Set when configs changed and the user hasn't opened the detail yet.
    var hasUnseenUpdate: Bool = false
    /// Whether change notifications are sent for this subscription.
    var notify: Bool = true
    /// Last refresh error, if the most recent check failed.
    var lastError: String? = nil

    var configCount: Int { lastConfigs.count }

    /// Host of the source URL, used as a default display name.
    static func defaultName(from source: String?) -> String {
        if let source, let host = URL(string: source)?.host, !host.isEmpty {
            return host
        }
        return "Подписка"
    }
}
