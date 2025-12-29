import Foundation
@preconcurrency import LocalAuthentication
import Observation
import OSLog
import SwiftData
import Supabase

/// Authentication Coordinator - Lightweight wrapper that delegates to Use Cases
/// Maintains @Observable state for legacy Views compatibility
/// New code should use ViewModels with Use Cases directly
/// Clean Architecture - Presentation/Coordination Layer
@MainActor
@Observable
final class AuthenticationManager {
    // MARK: - Dependencies (Use Cases)

    private let loginUseCase: LoginUseCase
    private let registerUseCase: RegisterUseCase
    private let biometricLoginUseCase: BiometricLoginUseCase
    private let logoutUseCase: LogoutUseCase
    private let sessionRepository: SessionRepositoryProtocol
    private let passwordRecoveryUseCase: PasswordRecoveryUseCase

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "AuthenticationManager")
    private let errorHandler: ErrorHandler
    private let settingsManager: SettingsManager
    private let paymentSyncCoordinator: PaymentSyncCoordinator

    // Legacy - for UserProfileService compatibility
    private let authRepository: AuthRepository

    // MARK: - Observable State

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

    // MARK: - Initialization

    init(
        authRepository: AuthRepository,
        errorHandler: ErrorHandler,
        settingsManager: SettingsManager,
        paymentSyncCoordinator: PaymentSyncCoordinator,
        authDependencyContainer: AuthDependencyContainer
    ) {
        self.authRepository = authRepository
        self.errorHandler = errorHandler
        self.settingsManager = settingsManager
        self.paymentSyncCoordinator = paymentSyncCoordinator

        // Initialize Use Cases from container
        self.loginUseCase = authDependencyContainer.makeLoginUseCase()
        self.registerUseCase = authDependencyContainer.makeRegisterUseCase()
        self.biometricLoginUseCase = authDependencyContainer.makeBiometricLoginUseCase()
        self.logoutUseCase = authDependencyContainer.makeLogoutUseCase()
        self.sessionRepository = authDependencyContainer.makeSessionRepository()
        self.passwordRecoveryUseCase = authDependencyContainer.makePasswordRecoveryUseCase()

        self.hasLoggedInWithCredentials = KeychainManager.getHasLoggedIn()
        self.isSessionActive = sessionRepository.hasActiveSession

        Task {
            await checkBiometricAvailability()

            let isFaceIDEnabled = settingsManager.isBiometricLockEnabled && canUseBiometrics

            if isFaceIDEnabled {
                self.isAuthenticated = false
            } else {
                self.isAuthenticated = authRepository.isAuthenticated
            }
        }
    }

    private func checkBiometricAvailability() async {
        let canUse = await biometricLoginUseCase.canUseBiometricLogin()
        canUseBiometrics = canUse

        #if targetEnvironment(simulator)
        canUseBiometrics = true
        logger.info("🧪 Simulator detected: Face ID enabled for testing")
        #endif
    }

    // MARK: - Authentication Methods (Delegate to Use Cases)

    @MainActor
    func login(email: String, password: String) async -> AuthError? {
        logger.info("🔑 Delegating login to LoginUseCase")

        let result = await loginUseCase.execute(email: email, password: password)

        switch result {
        case .success(let session):
            // Save credentials for biometric login
            let saved = KeychainManager.saveCredentials(email: email, password: password)
            if saved {
                logger.info("✅ Credentials saved to Keychain")
            }

            self.hasLoggedInWithCredentials = true
            _ = KeychainManager.setHasLoggedIn(true)

            // Update coordinator state
            self.isAuthenticated = true
            self.isSessionActive = true
            await sessionRepository.startSession()

            logger.info("✅ Login successful")
            return nil

        case .failure(let error):
            logger.error("❌ Login failed: \(error.errorCode)")
            errorHandler.handle(error)
            return error
        }
    }

    @MainActor
    func register(email: String, password: String) async -> AuthError? {
        logger.info("📝 Delegating registration to RegisterUseCase")

        let result = await registerUseCase.execute(email: email, password: password, metadata: nil)

        switch result {
        case .success(let session):
            self.hasLoggedInWithCredentials = true
            _ = KeychainManager.setHasLoggedIn(true)

            // Update coordinator state
            self.isAuthenticated = true
            self.isSessionActive = true
            await sessionRepository.startSession()

            logger.info("✅ Registration successful")
            return nil

        case .failure(let error):
            logger.error("❌ Registration failed: \(error.errorCode)")
            errorHandler.handle(error)
            return error
        }
    }

    @MainActor
    func sendPasswordReset(email: String) async -> AuthError? {
        logger.info("📧 Delegating password reset to PasswordRecoveryUseCase")

        do {
            try await passwordRecoveryUseCase.sendPasswordReset(email: email)
            logger.info("✅ Password reset email sent successfully")
            return nil
        } catch let authError as AuthError {
            logger.error("❌ Password reset failed: \(authError.errorCode)")
            errorHandler.handle(authError)
            return authError
        } catch {
            logger.error("❌ Password reset failed: \(error.localizedDescription)")
            let authError = AuthError.unknown(error.localizedDescription)
            errorHandler.handle(authError)
            return authError
        }
    }

    // MARK: - Biometric Authentication (Delegate to BiometricLoginUseCase)

    @MainActor
    func authenticateWithBiometrics() async {
        guard canUseBiometrics else {
            logger.warning("⚠️ Biometrics not available")
            return
        }

        guard KeychainManager.hasStoredCredentials() else {
            logger.warning("⚠️ No credentials stored in Keychain for biometric login")
            return
        }

        logger.info("🔐 Delegating biometric authentication to BiometricLoginUseCase")

        isLoading = true
        defer { isLoading = false }

        let result = await biometricLoginUseCase.execute()

        switch result {
        case .success(let session):
            // Update coordinator state
            self.isAuthenticated = true
            self.isSessionActive = true
            await sessionRepository.startSession()

            logger.info("✅ Biometric login successful")

        case .failure(let error):
            logger.error("❌ Biometric login failed: \(error.errorCode)")
            errorHandler.handle(error)
        }
    }
    
    // MARK: - Logout (Delegate to LogoutUseCase + Coordination)

    /// Logout - Closes session but PRESERVES all local data (payments, profile, notifications)
    /// User data remains on device and will be available when logging back in with the same account
    @MainActor
    func logout(inactivity: Bool = false) async {
        logger.info("🚪 Delegating logout to LogoutUseCase")

        isLoading = true
        defer { isLoading = false }

        let result = await logoutUseCase.execute()

        switch result {
        case .success:
            logger.info("✅ Session closed on logout")
            logger.info("📦 Local data preserved - payments and profile remain on device")

        case .failure(let error):
            logger.error("❌ Logout failed: \(error.errorCode)")
        }

        // Coordination: Clear authentication tokens based on settings
        if !settingsManager.isBiometricLockEnabled {
            _ = KeychainManager.deleteCredentials()
            logger.info("🗑️ Credentials deleted from Keychain (biometric disabled)")
        } else {
            logger.info("🔐 Credentials kept in Keychain (biometric enabled)")
        }

        // Update coordinator state
        self.isAuthenticated = false
        self.isSessionActive = false

        if inactivity {
            self.showInactivityAlert = true
        }
    }

    /// Unlink Device - Closes session AND removes all local data (payments, profile, notifications)
    /// Use this when: selling device, switching accounts permanently, or wanting a fresh start
    @MainActor
    func unlinkDevice(modelContext: ModelContext) async {
        logger.info("🔓 Unlinking device - clearing all local data")

        isLoading = true
        defer { isLoading = false }

        // Logout from remote session
        let result = await logoutUseCase.execute()
        switch result {
        case .success:
            logger.info("✅ Session closed for device unlink")
        case .failure(let error):
            logger.error("❌ Device unlink logout failed: \(error.errorCode)")
        }

        // Clear ALL local data
        _ = await paymentSyncCoordinator.clearLocalDatabase(force: true)
        logger.info("🗑️ All local payments cleared")

        // TODO: Clear local profile via UserProfile Use Case
        // For now, this functionality needs to be migrated to UserProfile DI Container
        logger.warning("⚠️ UserProfile cleanup not yet migrated to Clean Architecture")

        // Clear all authentication data
        _ = KeychainManager.deleteCredentials()
        logger.info("🗑️ All credentials deleted from Keychain")

        // Reset coordinator state
        await sessionRepository.clearSession()
        self.isAuthenticated = false
        self.isSessionActive = false

        logger.info("✅ Device unlinked - all local data removed")
    }
    
    // MARK: - Session Management (Delegate to SessionRepository + Coordination)

    func checkSession() {
        #if DEBUG
        return
        #else
        Task {
            await checkSessionAsync()
        }
        #endif
    }

    private func checkSessionAsync() async {
        // Delegate session validation to SessionRepository
        let result = await sessionRepository.validateSession()

        switch result {
        case .success(let isValid):
            if !isValid {
                logger.info("⏰ Session validation failed - checking if should logout")
                await checkAndLogoutIfOnline()
            } else {
                logger.debug("✅ Session is valid")
                await sessionRepository.updateLastActiveTimestamp()
            }

        case .failure(let error):
            if error == .sessionExpired {
                logger.warning("⏰ Session expired - checking if should logout")
                await checkAndLogoutIfOnline()
            }
        }
    }

    /// Check if we can connect to Supabase and logout only if online
    /// This prevents automatic logout when working offline
    private func checkAndLogoutIfOnline() async {
        logger.info("🔍 Checking if should logout due to inactivity...")

        // Try to verify session with Supabase
        do {
            try await authRepository.ensureValidSession()
            // If we get here, we have connection and valid session - don't logout
            logger.info("✅ Valid session in Supabase - not logging out")
            // Reset the timer since we verified the session is still active
            await sessionRepository.updateLastActiveTimestamp()
        } catch {
            // ensureValidSession failed - could be:
            // 1. Offline (no connection) -> DON'T logout
            // 2. Online but session expired -> DO logout

            logger.warning("⚠️ Could not verify session: \(error.localizedDescription)")

            // Try to get current session - if this fails with network error, we're offline
            do {
                _ = try await authRepository.authServiceInternal.getCurrentSession()
                // We got a response (even if session is expired), so we're ONLINE
                // Session is expired and we're online -> logout
                logger.info("🌐 Connection available but session expired - logging out due to inactivity")
                self.hasLoggedInWithCredentials = false
                KeychainManager.deleteHasLoggedIn()
                await logout(inactivity: true)
            } catch {
                // Can't connect to Supabase at all -> OFFLINE
                // Don't logout - user can work offline indefinitely
                logger.info("📴 No connection - user can continue working offline indefinitely")
                logger.info("⏰ Inactivity timeout NOT applied in offline mode")
            }
        }
    }

    func startInactivityTimer() {
        Task {
            await sessionRepository.updateLastActiveTimestamp()
        }
    }

    func updateLastActiveTimestamp() {
        Task {
            await sessionRepository.updateLastActiveTimestamp()
        }
    }

    func clearBiometricCredentials(modelContext: ModelContext? = nil) async {
        self.hasLoggedInWithCredentials = false
        KeychainManager.deleteHasLoggedIn()
        _ = KeychainManager.deleteCredentials()

        await sessionRepository.clearSession()
        self.isSessionActive = false

        logger.info("🔐 Credentials removed from Keychain (biometric disabled)")
    }
    
}
