import Foundation

/// Name and birth date, stored in an App Group so the widget can read them.
enum ProfileStore {
    /// Must match the App Group in both .entitlements files (Config/).
    static let appGroup = "group.ch.appic.chliinimuus"

    enum Key {
        static let name = "profile.name"
        static let birthDate = "profile.birthDate" // Double: timeIntervalSinceReferenceDate
        static let isConfigured = "profile.isConfigured"
    }

    static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroup) ?? .standard
    }

    struct Profile: Equatable {
        var name: String
        var birthDate: Date
    }

    /// The saved profile, or nil if the user has not set a birth date yet.
    static func load() -> Profile? {
        let d = defaults
        guard d.bool(forKey: Key.isConfigured) else { return nil }
        return Profile(
            name: d.string(forKey: Key.name) ?? "",
            birthDate: Date(timeIntervalSinceReferenceDate: d.double(forKey: Key.birthDate))
        )
    }

    static func save(_ profile: Profile) {
        let d = defaults
        d.set(profile.name, forKey: Key.name)
        d.set(profile.birthDate.timeIntervalSinceReferenceDate, forKey: Key.birthDate)
        d.set(true, forKey: Key.isConfigured)
    }
}
