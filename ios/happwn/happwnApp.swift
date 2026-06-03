import SwiftUI

@main
struct HappwnApp: App {
    @StateObject private var settings: Settings
    @StateObject private var store: SubscriptionStore
    @StateObject private var coordinator: RefreshCoordinator
    @Environment(\.scenePhase) private var scenePhase

    init() {
        let settings = Settings()
        let store = SubscriptionStore()
        _settings = StateObject(wrappedValue: settings)
        _store = StateObject(wrappedValue: store)
        _coordinator = StateObject(wrappedValue: RefreshCoordinator(store: store, settings: settings))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(settings)
                .environmentObject(store)
                .environmentObject(coordinator)
                .tint(settings.accent.color)
                .preferredColorScheme(settings.appearance.colorScheme)
                .task {
                    NotificationService().enableForegroundPresentation()
                    if settings.notificationsEnabled {
                        await NotificationService().requestAuthorization()
                    }
                }
                .onChange(of: scenePhase) { phase in
                    if phase == .active {
                        Task { await coordinator.refreshAll() }
                    }
                }
        }
    }
}
