import Foundation

/// Re-fetches saved subscriptions, detects config changes, and fires
/// notifications. The extraction closure is injectable for testing.
struct RefreshService {
    /// (link, userAgent, hwid) -> ExtractionResult. Defaults to the real service.
    var extract: (String, String, String) async throws -> ExtractionResult = { link, ua, hwid in
        try await ExtractionService().run(link: link, userAgent: ua, hwid: hwid)
    }

    /// Refreshes every subscription, returning updated copies. One failing
    /// subscription does not abort the others.
    func refreshAll(
        _ subs: [SavedSubscription],
        userAgent: String,
        hwid: String,
        notificationsEnabled: Bool,
        notifier: SubscriptionNotifying,
        now: Date = Date()
    ) async -> [SavedSubscription] {
        var updated: [SavedSubscription] = []
        updated.reserveCapacity(subs.count)
        for sub in subs {
            updated.append(await refresh(sub, userAgent: userAgent, hwid: hwid,
                                         notificationsEnabled: notificationsEnabled,
                                         notifier: notifier, now: now))
        }
        return updated
    }

    private func refresh(
        _ original: SavedSubscription,
        userAgent: String,
        hwid: String,
        notificationsEnabled: Bool,
        notifier: SubscriptionNotifying,
        now: Date
    ) async -> SavedSubscription {
        var sub = original
        sub.lastCheckedAt = now
        do {
            let result = try await extract(sub.link, userAgent, hwid)
            let newURIs = result.configs.map(\.uri)
            let diff = ChangeDetector.diff(old: sub.lastConfigs, new: newURIs)

            sub.mode = result.mode
            sub.source = result.source
            sub.lastError = nil

            if diff.changed {
                sub.lastConfigs = newURIs
                sub.lastChangedAt = now
                sub.hasUnseenUpdate = true
                if notificationsEnabled && sub.notify {
                    await notifier.notifyChange(subscription: sub, added: diff.added, removed: diff.removed)
                }
            }
        } catch {
            sub.lastError = error.localizedDescription
        }
        return sub
    }
}
