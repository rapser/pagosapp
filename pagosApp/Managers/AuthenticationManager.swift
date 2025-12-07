import Foundation
import LocalAuthentication
import Combine
import OSLog
import SwiftData

@MainActor
class AuthenticationManager: ObservableObject {
    public let authService: AuthenticationService
    private var cancellables = Set<AnyCancellable>()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "Authentication")
    private let errorHandler = ErrorHandler.shared

    private let lastActiveTimestampKey = "lastActiveTimestamp"
    private let sessionTimeoutInSeconds: TimeInterval = 604800 // 1 semana (7 días * 24 horas * 60 minutos * 60 segundos)
    
    @Published var isAuthenticated = false
    @Published var canUseBiometrics = false
    @Published var showInactivityAlert = false
    @Published var hasLoggedInWithCredentials = false
    @Published var isLoading: Bool = false
    
    init(authService: AuthenticationService) {
        self.authService = authService
        self.hasLoggedInWithCredentials = KeychainManager.getHasLoggedIn()

        checkBiometricAvailability()

        // Check if there's a Supabase session available
        let hasSupabaseSession = (authService.isAuthenticated)

        // Check if Face ID is enabled
        let isFaceIDEnabled = SettingsManager.shared.isBiometricLockEnabled && canUseBiometrics

        // Determine initial authentication state
        if isFaceIDEnabled {
            // If Face ID is enabled, ALWAYS require Face ID login for security
            self.isAuthenticated = false
        } else {
            // If Face ID is NOT enabled, use Supabase session state
            self.isAuthenticated = hasSupabaseSession
        }

        // Observe changes from the injected AuthenticationService
        authService.isAuthenticatedPublisher
            .sink { [weak self] isAuthenticated in
                guard let self = self else { return }

                // Only auto-update if Face ID is NOT enabled
                let isFaceIDEnabled = SettingsManager.shared.isBiometricLockEnabled && self.canUseBiometrics
                if !isFaceIDEnabled {
                    self.isAuthenticated = isAuthenticated
                }
            }
            .store(in: &cancellables)
    }
    
    private func checkBiometricAvailability() {
        let context = LAContext()
        var error: NSError?
        
        // Check if biometrics can be evaluated
        let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        
        #if targetEnvironment(simulator)
        // In simulator, always allow Face ID for testing
        canUseBiometrics = true
        logger.info("🧪 Simulator detected: Face ID enabled for testing")
        #else
        // On real device, use actual biometric availability
        canUseBiometrics = canEvaluate
        if let error = error {
            logger.warning("Biometrics not available: \(error.localizedDescription)")
        }
        #endif
    }

    @MainActor
    func login(email: String, password: String) async -> AuthenticationError? {
        guard EmailValidator.isValidEmail(email) else {
            let error = AuthenticationError.invalidEmailFormat
            errorHandler.handle(error)
            return error
        }

        isLoading = true
        defer { isLoading = false }

        do {
            logger.info("Attempting login for \(email)")
            try await authService.signIn(email: email, password: password)
            self.hasLoggedInWithCredentials = true
            _ = KeychainManager.setHasLoggedIn(true)

            // Always save credentials to Keychain on successful login
            let saved = KeychainManager.saveCredentials(email: email, password: password)
            if saved {
                logger.info("✅ Credentials saved to Keychain")
            } else {
                logger.warning("⚠️ Failed to save credentials to Keychain")
            }

            // Manually set isAuthenticated to true after successful login
            self.isAuthenticated = true

            logger.info("✅ Login successful for \(email)")
            return nil
        } catch let authError as AuthenticationError {
            logger.error("❌ Login failed: \(authError.localizedDescription)")
            errorHandler.handle(authError)
            return authError
        } catch {
            logger.error("❌ Login failed with unknown error: \(error.localizedDescription)")
            let authError = AuthenticationError.unknown(error)
            errorHandler.handle(authError)
            return authError
        }
    }
    
    @MainActor
    func register(email: String, password: String) async -> AuthenticationError? {
        guard EmailValidator.isValidEmail(email) else {
            let error = AuthenticationError.invalidEmailFormat
            errorHandler.handle(error)
            return error
        }

        isLoading = true
        defer { isLoading = false }

        do {
            logger.info("Attempting registration for \(email)")
            try await authService.signUp(email: email, password: password)
            self.hasLoggedInWithCredentials = true
            _ = KeychainManager.setHasLoggedIn(true)

            // Manually set isAuthenticated to true after successful registration
            self.isAuthenticated = true

            logger.info("✅ Registration successful for \(email)")
            return nil
        } catch let authError as AuthenticationError {
            logger.error("❌ Registration failed: \(authError.localizedDescription)")
            errorHandler.handle(authError)
            return authError
        } catch {
            logger.error("❌ Registration failed with unknown error: \(error.localizedDescription)")
            let authError = AuthenticationError.unknown(error)
            errorHandler.handle(authError)
            return authError
        }
    }
    
    @MainActor
    func sendPasswordReset(email: String) async -> AuthenticationError? {
        guard EmailValidator.isValidEmail(email) else {
            let error = AuthenticationError.invalidEmailFormat
            errorHandler.handle(error)
            return error
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            logger.info("Attempting to send password reset for \(email)")
            try await authService.sendPasswordReset(email: email)
            logger.info("✅ Password reset email sent successfully for \(email)")
            return nil
        } catch let authError as AuthenticationError {
            logger.error("❌ Password reset failed: \(authError.localizedDescription)")
            errorHandler.handle(authError)
            return authError
        } catch {
            logger.error("❌ Password reset failed with unknown error: \(error.localizedDescription)")
            let authError = AuthenticationError.unknown(error)
            errorHandler.handle(authError)
            return authError
        }
    }
    
    @MainActor
    func authenticateWithBiometrics() async {
        guard canUseBiometrics else { return }
        
        // Check if credentials are stored
        guard KeychainManager.hasStoredCredentials() else {
            logger.warning("⚠️ No credentials stored in Keychain for Face ID")
            return
        }

        let context = LAContext()
        let reason = "Inicia sesión con Face ID para acceder a tus pagos."

        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] success, authenticationError in
            Task { @MainActor in
                guard let self = self else { return }
                
                if success {
                    // Face ID successful, now start loading and perform login
                    self.isLoading = true
                    
                    // Retrieve credentials from Keychain
                    guard let credentials = KeychainManager.retrieveCredentials() else {
                        self.logger.error("❌ Failed to retrieve credentials from Keychain")
                        self.isLoading = false
                        return
                    }
                    
                    // Perform login with retrieved credentials
                    self.logger.info("🔐 Face ID successful, logging in with stored credentials")
                    let error = await self.login(email: credentials.email, password: credentials.password)
                    
                    if error == nil {
                        self.logger.info("✅ Face ID login successful")
                    } else {
                        self.logger.error("❌ Face ID login failed: \(error?.localizedDescription ?? "unknown")")
                    }
                    
                    self.isLoading = false
                } else {
                    self.logger.warning("⚠️ Face ID authentication failed")
                    if let error = authenticationError {
                        self.logger.error("Face ID error: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    @MainActor
    func logout(inactivity: Bool = false, modelContext: ModelContext? = nil) async {
        isLoading = true
        defer { isLoading = false }

        // Always sign out from Supabase
        do {
            try await authService.signOut()
            logger.info("✅ Supabase session closed on logout")
        } catch let authError as AuthenticationError {
            logger.error("Logout failed with auth error: \(authError.localizedDescription)")
        } catch {
            logger.error("Unknown logout error: \(error.localizedDescription)")
        }

        // Always clear local database on logout
        // This ONLY clears SwiftData locally, NEVER touches Supabase
        PaymentSyncManager.shared.clearLocalDatabase(modelContext: modelContext)
        logger.info("Local SwiftData database cleared on logout (Supabase untouched)")

        // If Face ID is NOT enabled, delete credentials from Keychain
        if !SettingsManager.shared.isBiometricLockEnabled {
            _ = KeychainManager.deleteCredentials()
            logger.info("🗑️ Credentials deleted from Keychain (Face ID disabled)")
        } else {
            logger.info("🔐 Credentials kept in Keychain (Face ID enabled)")
        }

        // Clear timestamp
        UserDefaults.standard.removeObject(forKey: self.lastActiveTimestampKey)

        // Manually set isAuthenticated to false to show login screen
        self.isAuthenticated = false

        if inactivity {
            self.showInactivityAlert = true
        }
    }
    
    func checkSession() {
        #if DEBUG
        return
        #else
        if let lastActiveTimestamp = UserDefaults.standard.object(forKey: lastActiveTimestampKey) as? Date {
            let elapsedTime = Date().timeIntervalSince(lastActiveTimestamp)
            if elapsedTime > sessionTimeoutInSeconds {
                Task {
                    // Clear hasLoggedInWithCredentials since session is too old
                    // This will require user to login with email/password again
                    // BUT we DON'T touch isBiometricLockEnabled (the switch stays ON)
                    self.hasLoggedInWithCredentials = false
                    KeychainManager.deleteHasLoggedIn()

                    // Full logout - always close Supabase session
                    await logout(inactivity: true)
                }
            }
        } else {
            startInactivityTimer()
        }
        #endif
    }
    
    func startInactivityTimer() {
        updateLastActiveTimestamp()
    }

    func updateLastActiveTimestamp() {
        UserDefaults.standard.set(Date(), forKey: lastActiveTimestampKey)
    }

    /// Clears the biometric login capability for this device
    /// This should be called when the user explicitly disables Face ID in settings
    func clearBiometricCredentials(modelContext: ModelContext? = nil) async {
        self.hasLoggedInWithCredentials = false
        KeychainManager.deleteHasLoggedIn()
        
        // Delete stored credentials from Keychain when Face ID is disabled
        _ = KeychainManager.deleteCredentials()
        logger.info("🔐 Credentials removed from Keychain (Face ID disabled)")
    }
}
