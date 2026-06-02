import Foundation
import Combine

/// User-editable request identity, persisted in UserDefaults.
final class Settings: ObservableObject {
    @Published var userAgent: String {
        didSet { defaults.set(userAgent, forKey: Keys.userAgent) }
    }
    @Published var hwid: String {
        didSet { defaults.set(hwid, forKey: Keys.hwid) }
    }

    private let defaults: UserDefaults

    private enum Keys {
        static let userAgent = "happwn.userAgent"
        static let hwid = "happwn.hwid"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.userAgent = defaults.string(forKey: Keys.userAgent) ?? "Happ/1.0"
        self.hwid = defaults.string(forKey: Keys.hwid) ?? ""
    }
}
