//
//  UserDefaultsLoginAttemptTracker.swift
//  pagosApp
//
//  Local lockout after repeated failed password logins (client-side guard).
//

import Foundation

@MainActor
final class UserDefaultsLoginAttemptTracker: LoginAttemptTracking {
    static let shared = UserDefaultsLoginAttemptTracker()

    private let defaults: UserDefaults
    private let maxFailuresBeforeLockout = 5
    private let lockoutDuration: TimeInterval = 15 * 60

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func lockoutUntilIfActive(forNormalizedEmail email: String) -> Date? {
        let key = baseKey(for: email)
        guard let interval = defaults.object(forKey: key + ".lockout") as? TimeInterval else { return nil }
        let until = Date(timeIntervalSince1970: interval)
        if until <= Date() {
            defaults.removeObject(forKey: key + ".lockout")
            defaults.removeObject(forKey: key + ".failures")
            return nil
        }
        return until
    }

    func recordFailedPasswordAttempt(forNormalizedEmail email: String) {
        let key = baseKey(for: email)
        if lockoutUntilIfActive(forNormalizedEmail: email) != nil { return }

        var count = defaults.integer(forKey: key + ".failures")
        count += 1
        defaults.set(count, forKey: key + ".failures")

        if count >= maxFailuresBeforeLockout {
            let until = Date().addingTimeInterval(lockoutDuration)
            defaults.set(until.timeIntervalSince1970, forKey: key + ".lockout")
            defaults.set(0, forKey: key + ".failures")
        }
    }

    func recordSuccessfulLogin(forNormalizedEmail email: String) {
        let key = baseKey(for: email)
        defaults.removeObject(forKey: key + ".failures")
        defaults.removeObject(forKey: key + ".lockout")
    }

    private func baseKey(for normalizedEmail: String) -> String {
        "auth.loginAttempts.\(normalizedEmail)"
    }
}
