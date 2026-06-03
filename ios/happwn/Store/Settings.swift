import Foundation
import Combine

/// User-editable request identity and appearance, persisted in UserDefaults.
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

    private let defaults: UserDefaults

    private enum Keys {
        static let userAgent = "happwn.userAgent"
        static let hwid = "happwn.hwid"
        static let accent = "happwn.accent"
        static let appearance = "happwn.appearance"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.userAgent = defaults.string(forKey: Keys.userAgent) ?? "Happ/1.0"
        self.hwid = defaults.string(forKey: Keys.hwid) ?? ""
        self.accent = AppAccent(rawValue: defaults.string(forKey: Keys.accent) ?? "") ?? .indigo
        self.appearance = AppAppearance(rawValue: defaults.string(forKey: Keys.appearance) ?? "") ?? .system
    }
}
