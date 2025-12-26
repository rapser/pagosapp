
import Foundation
import Observation

/// Manages app-wide settings
/// Refactored to support Dependency Injection (no more Singleton)
@MainActor
@Observable
final class SettingsManager {
    // MARK: - Properties

    var isBiometricLockEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isBiometricLockEnabled, forKey: "isBiometricLockEnabled")
        }
    }

    // MARK: - Initialization

    init() {
        // Default to false if key not found. User has to explicitly enable it.
        self.isBiometricLockEnabled = UserDefaults.standard.bool(forKey: "isBiometricLockEnabled")
    }
}
