import Foundation
import LocalAuthentication

class AuthenticationManager: ObservableObject {
    private struct DummyUser {
        static let email = "test@example.com"
        static let password = "password123"
    }
    
    private let isAuthenticatedKey = "isAuthenticated"
    private let hasLoggedInWithCredentialsKey = "hasLoggedInWithCredentials"
    private let lastActiveTimestampKey = "lastActiveTimestamp"
    private let sessionTimeoutInSeconds: TimeInterval = 300 // 5 minutos
    
    @Published var isAuthenticated = false
    @Published var canUseBiometrics = false
    @Published var showInactivityAlert = false
    @Published var hasLoggedInWithCredentials = false
    
    init() {
        self.isAuthenticated = UserDefaults.standard.bool(forKey: isAuthenticatedKey)
        self.hasLoggedInWithCredentials = UserDefaults.standard.bool(forKey: hasLoggedInWithCredentialsKey)
        checkBiometricAvailability()
    }
    
    private func checkBiometricAvailability() {
        let context = LAContext()
        var error: NSError?
        canUseBiometrics = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    func login(email: String, password: String) -> LoginError? {
        guard EmailValidator.isValidEmail(email) else {
            return .invalidEmailFormat
        }
        
        if email.lowercased() == DummyUser.email && password == DummyUser.password {
            DispatchQueue.main.async {
                self.isAuthenticated = true
                UserDefaults.standard.set(true, forKey: self.isAuthenticatedKey)
                UserDefaults.standard.set(true, forKey: self.hasLoggedInWithCredentialsKey)
            }
            return nil
        } else {
            return .wrongCredentials
        }
    }
    
    func authenticateWithBiometrics() {
        guard canUseBiometrics else { return }
        
        let context = LAContext()
        let reason = "Inicia sesión con Face ID para acceder a tus pagos."

        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
            DispatchQueue.main.async {
                if success {
                    self.isAuthenticated = true
                    UserDefaults.standard.set(true, forKey: self.isAuthenticatedKey)
                } else {
                    // Autenticación biométrica fallida
                }
            }
        }
    }
    
    func logout(inactivity: Bool = false) {
        DispatchQueue.main.async {
            self.isAuthenticated = false
            UserDefaults.standard.removeObject(forKey: self.isAuthenticatedKey)
            UserDefaults.standard.removeObject(forKey: self.lastActiveTimestampKey)
            if inactivity {
                self.showInactivityAlert = true
            }
        }
    }
    
    func checkSession() {
        if let lastActiveTimestamp = UserDefaults.standard.object(forKey: lastActiveTimestampKey) as? Date {
            let elapsedTime = Date().timeIntervalSince(lastActiveTimestamp)
            if elapsedTime > sessionTimeoutInSeconds {
                logout(inactivity: true)
            }
        }
    }
    
    func updateLastActiveTimestamp() {
        UserDefaults.standard.set(Date(), forKey: lastActiveTimestampKey)
    }
}
