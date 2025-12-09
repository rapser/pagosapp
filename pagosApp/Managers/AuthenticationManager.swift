import Foundation
@preconcurrency import LocalAuthentication
import Observation
import OSLog
import SwiftData
import Supabase

/// Manager for authentication with biometric support
/// Wraps AuthRepository with Face ID functionality
/// Modern iOS 18+ using @Observable macro
@MainActor
@Observable
final class AuthenticationManager {
    private let authRepository: AuthRepository
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "Authentication")
    private let errorHandler: ErrorHandler
    private let settingsManager: SettingsManager
    private let paymentSyncManager: PaymentSyncManager

    private let lastActiveTimestampKey = "lastActiveTimestamp"
    private let sessionActiveKey = "sessionActive"
    private let sessionTimeoutInSeconds: TimeInterval = 604800 // 1 week

    var isAuthenticated = false
    var isSessionActive = false
    var canUseBiometrics = false
    var showInactivityAlert = false
    var hasLoggedInWithCredentials = false
    var isLoading: Bool = false

    /// Exposes the Supabase client for legacy compatibility
    /// Use only when necessary (e.g., UserProfileService)
    var supabaseClient: SupabaseClient? {
        return authRepository.supabaseClient
    }

    init(
        authRepository: AuthRepository,
        errorHandler: ErrorHandler,
        settingsManager: SettingsManager,
        paymentSyncManager: PaymentSyncManager
    ) {
        self.authRepository = authRepository
        self.errorHandler = errorHandler
        self.settingsManager = settingsManager
        self.paymentSyncManager = paymentSyncManager
        self.hasLoggedInWithCredentials = KeychainManager.getHasLoggedIn()
        self.isSessionActive = UserDefaults.standard.bool(forKey: sessionActiveKey)

        checkBiometricAvailability()

        let isFaceIDEnabled = settingsManager.isBiometricLockEnabled && canUseBiometrics

        if isFaceIDEnabled {
            self.isAuthenticated = false
        } else {
            self.isAuthenticated = authRepository.isAuthenticated
        }

        // With @Observable, property changes are automatically observed
        // Set up observation task for auth state
        Task { @MainActor in
            await observeAuthState()
        }
    }
    
    private func observeAuthState() async {
        // Continuous observation of auth state
        // In modern SwiftUI with @Observable, bindings work automatically
    }
    
    private func checkBiometricAvailability() {
        let context = LAContext()
        var error: NSError?
        
        let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        
        #if targetEnvironment(simulator)
        canUseBiometrics = true
        logger.info("🧪 Simulator detected: Face ID enabled for testing")
        #else
        canUseBiometrics = canEvaluate
        if let error = error {
            logger.warning("Biometrics not available: \(error.localizedDescription)")
        }
        #endif
    }

    // MARK: - Authentication Methods
    
    @MainActor
    func login(email: String, password: String) async -> AuthenticationError? {
        do {
            logger.info("Attempting login for \(email)")
            
            try await authRepository.login(email: email, password: password)
            
            self.hasLoggedInWithCredentials = true
            _ = KeychainManager.setHasLoggedIn(true)

            let saved = KeychainManager.saveCredentials(email: email, password: password)
            if saved {
                logger.info("✅ Credentials saved to Keychain")
            } else {
                logger.warning("⚠️ Failed to save credentials to Keychain")
            }

            self.isAuthenticated = true
            self.isSessionActive = true
            UserDefaults.standard.set(true, forKey: sessionActiveKey)
            logger.info("✅ Login successful for \(email)")
            return nil
            
        } catch let authError as AuthError {
            logger.error("❌ Login failed: \(authError.localizedDescription)")
            let legacyError = mapToLegacyError(authError)
            errorHandler.handle(legacyError)
            return legacyError
        } catch {
            logger.error("❌ Login failed with unknown error: \(error.localizedDescription)")
            let authError = AuthenticationError.unknown(error)
            errorHandler.handle(authError)
            return authError
        }
    }
    
    @MainActor
    func register(email: String, password: String) async -> AuthenticationError? {
        do {
            logger.info("Attempting registration for \(email)")
            
            try await authRepository.register(email: email, password: password)
            
            self.hasLoggedInWithCredentials = true
            _ = KeychainManager.setHasLoggedIn(true)
            self.isAuthenticated = true
            self.isSessionActive = true
            UserDefaults.standard.set(true, forKey: sessionActiveKey)

            logger.info("✅ Registration successful for \(email)")
            return nil
            
        } catch let authError as AuthError {
            logger.error("❌ Registration failed: \(authError.localizedDescription)")
            let legacyError = mapToLegacyError(authError)
            errorHandler.handle(legacyError)
            return legacyError
        } catch {
            logger.error("❌ Registration failed with unknown error: \(error.localizedDescription)")
            let authError = AuthenticationError.unknown(error)
            errorHandler.handle(authError)
            return authError
        }
    }
    
    @MainActor
    func sendPasswordReset(email: String) async -> AuthenticationError? {
        do {
            logger.info("Attempting to send password reset for \(email)")
            try await authRepository.sendPasswordReset(email: email)
            logger.info("✅ Password reset email sent successfully for \(email)")
            return nil
            
        } catch let authError as AuthError {
            logger.error("❌ Password reset failed: \(authError.localizedDescription)")
            let legacyError = mapToLegacyError(authError)
            errorHandler.handle(legacyError)
            return legacyError
        } catch {
            logger.error("❌ Password reset failed with unknown error: \(error.localizedDescription)")
            let authError = AuthenticationError.unknown(error)
            errorHandler.handle(authError)
            return authError
        }
    }
    
    // MARK: - Biometric Authentication
    
    @MainActor
    func authenticateWithBiometrics() async {
        guard canUseBiometrics else { return }
        
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
                    self.isLoading = true
                    
                    guard let credentials = KeychainManager.retrieveCredentials(context: context) else {
                        self.logger.error("❌ Failed to retrieve credentials from Keychain")
                        self.isLoading = false
                        return
                    }
                    
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
    
    // MARK: - Logout
    
    @MainActor
    func logout(inactivity: Bool = false, modelContext: ModelContext? = nil) async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await authRepository.logout()
            logger.info("✅ Session closed on logout")
        } catch {
            logger.error("Logout failed with error: \(error.localizedDescription)")
        }

        paymentSyncManager.clearLocalDatabase(modelContext: modelContext)
        logger.info("Local SwiftData database cleared on logout")

        if !settingsManager.isBiometricLockEnabled {
            _ = KeychainManager.deleteCredentials()
            logger.info("🗑️ Credentials deleted from Keychain (Face ID disabled)")
        } else {
            logger.info("🔐 Credentials kept in Keychain (Face ID enabled)")
        }

        UserDefaults.standard.removeObject(forKey: self.lastActiveTimestampKey)
        self.isAuthenticated = false
        self.isSessionActive = false
        UserDefaults.standard.set(false, forKey: sessionActiveKey)

        if inactivity {
            self.showInactivityAlert = true
        }
    }
    
    // MARK: - Session Management
    
    func checkSession() {
        #if DEBUG
        return
        #else
        if let lastActiveTimestamp = UserDefaults.standard.object(forKey: lastActiveTimestampKey) as? Date {
            let elapsedTime = Date().timeIntervalSince(lastActiveTimestamp)
            if elapsedTime > sessionTimeoutInSeconds {
                Task {
                    self.hasLoggedInWithCredentials = false
                    KeychainManager.deleteHasLoggedIn()
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

    func clearBiometricCredentials(modelContext: ModelContext? = nil) async {
        self.hasLoggedInWithCredentials = false
        KeychainManager.deleteHasLoggedIn()
        _ = KeychainManager.deleteCredentials()
        self.isSessionActive = false
        UserDefaults.standard.set(false, forKey: sessionActiveKey)
        logger.info("🔐 Credentials removed from Keychain (Face ID disabled)")
    }
    
    // MARK: - Error Mapping
    
    private func mapToLegacyError(_ authError: AuthError) -> AuthenticationError {
        switch authError {
        case .invalidCredentials, .userNotFound:
            return .wrongCredentials
        case .emailAlreadyExists:
            return .wrongCredentials
        case .weakPassword, .invalidEmail:
            return .invalidEmailFormat
        case .sessionExpired:
            return .sessionExpired
        case .networkError:
            return .networkError
        case .unknown(let message):
            return .unknown(NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: message]))
        }
    }
}
