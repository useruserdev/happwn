import Foundation
import UserNotifications

/// Sends a local notification when a subscription's configs change.
/// Injectable so RefreshService can be tested with a spy.
protocol SubscriptionNotifying {
    func notifyChange(subscription: SavedSubscription, added: Int, removed: Int) async
}

/// Lets change notifications appear as a banner even while the app is open
/// (refreshes happen on launch / pull-to-refresh, i.e. in the foreground).
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .list])
    }
}

struct NotificationService: SubscriptionNotifying {
    /// userInfo key carrying the subscription id (for deep-linking on tap).
    static let subscriptionIDKey = "subscriptionID"

    /// Show notifications while the app is in the foreground.
    func enableForegroundPresentation() {
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }

    /// Request authorization; returns whether it was granted.
    @discardableResult
    func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    func notifyChange(subscription: SavedSubscription, added: Int, removed: Int) async {
        let content = UNMutableNotificationContent()
        content.title = subscription.name
        content.body = Self.body(added: added, removed: removed)
        content.sound = .default
        content.userInfo = [Self.subscriptionIDKey: subscription.id.uuidString]

        let request = UNNotificationRequest(
            identifier: subscription.id.uuidString,
            content: content,
            trigger: nil // deliver immediately
        )
        try? await UNUserNotificationCenter.current().add(request)
    }

    static func body(added: Int, removed: Int) -> String {
        var parts: [String] = []
        if added > 0 { parts.append("+\(added)") }
        if removed > 0 { parts.append("−\(removed)") }
        let delta = parts.isEmpty ? "" : " (\(parts.joined(separator: " / ")))"
        return "Подписка обновилась\(delta)"
    }
}
