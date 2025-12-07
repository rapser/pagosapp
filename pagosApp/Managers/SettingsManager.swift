import Foundation

@MainActor
class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    @Published var isBiometricLockEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isBiometricLockEnabled, forKey: "isBiometricLockEnabled")
        }
    }

    private init() {
        // Default to false if key not found. User has to explicitly enable it.
        self.isBiometricLockEnabled = UserDefaults.standard.bool(forKey: "isBiometricLockEnabled")
    }
}