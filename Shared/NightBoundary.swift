import Foundation

public struct NightBoundary: Codable, Hashable, Sendable {
    public var minutesAfterMidnight: Int

    public init(minutesAfterMidnight: Int = 60) {
        self.minutesAfterMidnight = minutesAfterMidnight
    }

    public var hour: Int { minutesAfterMidnight / 60 }
    public var minute: Int { minutesAfterMidnight % 60 }
}

public enum NightBoundaryStore {
    private static let key = "nightBoundaryMinutes"

    public static func load(from defaults: UserDefaults) -> NightBoundary {
        if defaults.object(forKey: key) == nil {
            return NightBoundary()
        }
        let storedMinutes = defaults.integer(forKey: key)
        return NightBoundary(minutesAfterMidnight: storedMinutes)
    }

    public static func save(_ boundary: NightBoundary, to defaults: UserDefaults) {
        defaults.set(boundary.minutesAfterMidnight, forKey: key)
    }
}
