import Foundation
import Combine

/// Drives refreshes from the UI (foreground, pull-to-refresh) and from the
/// background task, applying results to the store on the main actor.
@MainActor
final class RefreshCoordinator: ObservableObject {
    private let store: SubscriptionStore
    private let settings: Settings
    private let service: RefreshService
    private let notifier: SubscriptionNotifying

    @Published private(set) var isRefreshing = false

    init(store: SubscriptionStore,
         settings: Settings,
         service: RefreshService = RefreshService(),
         notifier: SubscriptionNotifying = NotificationService()) {
        self.store = store
        self.settings = settings
        self.service = service
        self.notifier = notifier
    }

    func refreshAll() async {
        guard !store.items.isEmpty, !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        let updated = await service.refreshAll(
            store.items,
            userAgent: settings.userAgent,
            hwid: settings.hwid,
            notificationsEnabled: settings.notificationsEnabled,
            notifier: notifier
        )
        store.replaceAll(updated)
    }
}
