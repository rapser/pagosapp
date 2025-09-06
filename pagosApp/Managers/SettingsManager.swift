import Foundation

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    @Published var isBiometricLockEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isBiometricLockEnabled, forKey: "isBiometricLockEnabled")
        }
    }

    private init() {
        // Si la clave no existe (primera vez que se abre la app), se establece en 'true' por defecto.
        if UserDefaults.standard.object(forKey: "isBiometricLockEnabled") == nil {
            self.isBiometricLockEnabled = true
        } else {
            self.isBiometricLockEnabled = UserDefaults.standard.bool(forKey: "isBiometricLockEnabled")
        }
    }
}