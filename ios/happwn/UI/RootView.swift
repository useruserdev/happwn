import SwiftUI

/// Two-tab shell. On iOS 26 SDK the native TabView renders the Liquid Glass
/// floating tab bar automatically; on earlier systems it falls back to the
/// standard bar.
struct RootView: View {
    var body: some View {
        TabView {
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
