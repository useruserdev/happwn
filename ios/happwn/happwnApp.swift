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
        let coordinator = RefreshCoordinator(store: store, settings: settings)
        _settings = StateObject(wrappedValue: settings)
        _store = StateObject(wrappedValue: store)
        _coordinator = StateObject(wrappedValue: coordinator)

        BackgroundRefresh.register(
            coordinator: { coordinator },
            minInterval: { settings.minRefreshInterval.seconds }
        )
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
                    if settings.notificationsEnabled {
                        await NotificationService().requestAuthorization()
                    }
                    if settings.backgroundRefreshEnabled {
                        BackgroundRefresh.schedule(minInterval: settings.minRefreshInterval.seconds)
                    }
                }
                .onChange(of: scenePhase) { phase in
                    switch phase {
                    case .active:
                        Task { await coordinator.refreshAll() }
                    case .background:
                        if settings.backgroundRefreshEnabled {
                            BackgroundRefresh.schedule(minInterval: settings.minRefreshInterval.seconds)
                        }
                    default:
                        break
                    }
                }
        }
    }
}
