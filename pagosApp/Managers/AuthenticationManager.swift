import Foundation
import LocalAuthentication
import Combine
import OSLog
import KeychainSwift

@MainActor
class AuthenticationManager: ObservableObject {
    public let authService: AuthenticationService
    private var cancellables = Set<AnyCancellable>()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "Authentication")
    private let errorHandler = ErrorHandler.shared
    private let keychain = KeychainSwift()

    private let hasLoggedInWithCredentialsKey = "hasLoggedInWithCredentials"
    private let lastActiveTimestampKey = "lastActiveTimestamp"
    private let sessionTimeoutInSeconds: TimeInterval = 604800 // 1 semana (7 días * 24 horas * 60 minutos * 60 segundos)
    
    @Published var isAuthenticated = false
    @Published var canUseBiometrics = false
    @Published var showInactivityAlert = false
    @Published var hasLoggedInWithCredentials = false
    @Published var isLoading: Bool = false
    
    init(authService: AuthenticationService) {
        self.authService = authService
        self.hasLoggedInWithCredentials = keychain.getBool(hasLoggedInWithCredentialsKey) ?? false

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
        canUseBiometrics = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
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
            keychain.set(true, forKey: self.hasLoggedInWithCredentialsKey)

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
            keychain.set(true, forKey: self.hasLoggedInWithCredentialsKey)

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

        isLoading = true

        let context = LAContext()
        let reason = "Inicia sesión con Face ID para acceder a tus pagos."

        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] success, authenticationError in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if success {
                    // Check if there's a Supabase session available
                    Task { @MainActor in
                        let hasSession = self.authService.isAuthenticated
                        if hasSession {
                            // Manually trigger authentication state update
                            self.isAuthenticated = true
                        }
                        self.isLoading = false
                    }
                } else {
                    self.isLoading = false
                }
            }
        }
    }
    
    @MainActor
    func logout(inactivity: Bool = false, keepSession: Bool = false, modelContext: ModelContext? = nil) async {
        isLoading = true
        defer { isLoading = false }

        // Only sign out from Supabase if we're NOT keeping the session
        // When keepSession is true, we maintain the Supabase session for Face ID to use later
        if !keepSession {
            do {
                try await authService.signOut()
            } catch let authError as AuthenticationError {
                logger.error("Logout failed with auth error: \(authError.localizedDescription)")
            } catch {
                logger.error("Unknown logout error: \(error.localizedDescription)")
            }
            
            // Clear local database when fully logging out (not keeping session)
            if let context = modelContext {
                PaymentSyncManager.shared.clearLocalDatabase(modelContext: context)
                logger.info("Local database cleared on logout")
            }
        }

        // Clear timestamp regardless
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
                    self.keychain.delete(self.hasLoggedInWithCredentialsKey)

                    // Full logout - clear Supabase session
                    await logout(inactivity: true, keepSession: false)
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
        keychain.delete(self.hasLoggedInWithCredentialsKey)

        // If user is currently logged in, force a full logout (including Supabase session)
        if self.isAuthenticated {
            await logout(keepSession: false, modelContext: modelContext)
        }
    }
}
