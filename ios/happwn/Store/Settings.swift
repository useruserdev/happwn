import Foundation
import Combine

/// User-editable request identity, appearance, and refresh prefs, persisted in UserDefaults.
final class Settings: ObservableObject {
    @Published var userAgent: String {
        didSet { defaults.set(userAgent, forKey: Keys.userAgent) }
    }
    @Published var hwid: String {
        didSet { defaults.set(hwid, forKey: Keys.hwid) }
    }
    @Published var accent: AppAccent {
        didSet { defaults.set(accent.rawValue, forKey: Keys.accent) }
    }
    @Published var appearance: AppAppearance {
        didSet { defaults.set(appearance.rawValue, forKey: Keys.appearance) }
    }
    @Published var notificationsEnabled: Bool {
        didSet { defaults.set(notificationsEnabled, forKey: Keys.notifications) }
    }

    private let defaults: UserDefaults

    private enum Keys {
        static let userAgent = "happwn.userAgent"
        static let hwid = "happwn.hwid"
        static let accent = "happwn.accent"
        static let appearance = "happwn.appearance"
        static let notifications = "happwn.notificationsEnabled"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.userAgent = defaults.string(forKey: Keys.userAgent) ?? "Happ/1.0"
        self.hwid = defaults.string(forKey: Keys.hwid) ?? ""
        self.accent = AppAccent(rawValue: defaults.string(forKey: Keys.accent) ?? "") ?? .indigo
        self.appearance = AppAppearance(rawValue: defaults.string(forKey: Keys.appearance) ?? "") ?? .system
        // Default ON so the app notifies about config changes (e.g. blocks) out of the box.
        self.notificationsEnabled = defaults.object(forKey: Keys.notifications) as? Bool ?? true
    }
}
