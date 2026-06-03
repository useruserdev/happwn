import SwiftUI

@main
struct HappwnApp: App {
    @StateObject private var settings = Settings()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(settings)
                .tint(settings.accent.color)
                .preferredColorScheme(settings.appearance.colorScheme)
        }
    }
}
