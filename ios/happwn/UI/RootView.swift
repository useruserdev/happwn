import SwiftUI

/// Three-tab shell. On iOS 26 SDK the native TabView renders the Liquid Glass
/// floating tab bar automatically; on earlier systems it falls back to the
/// standard bar.
struct RootView: View {
    var body: some View {
        TabView {
            NavigationStack {
                SubscriptionsListView()
            }
            .tabItem {
                Label("Подписки", systemImage: "square.stack.3d.up")
            }

            NavigationStack {
                ExtractView()
            }
            .tabItem {
                Label("Извлечь", systemImage: "arrow.down.doc")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Настройки", systemImage: "gearshape")
            }
        }
    }
}
