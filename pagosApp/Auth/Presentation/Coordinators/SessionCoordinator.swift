//
//  SessionCoordinator.swift
//  pagosApp
//
//  Session coordination layer - manages session lifecycle and UI state
//  Clean Architecture - Presentation/Coordination Layer
//

import Foundation
import Observation
import OSLog

/// Coordinates session lifecycle, inactivity detection, and authentication UI state
/// This is a lightweight presentation coordinator that delegates business logic to Use Cases
@MainActor
@Observable
final class SessionCoordinator {
    // MARK: - Observable State (UI)

    var isAuthenticated = false
    var isSessionActive = false
    var showInactivityAlert = false
    var isLoading: Bool = false
    var canUseBiometrics = false

    // MARK: - Dependencies

    private let loginUseCase: LoginUseCase
    private let registerUseCase: RegisterUseCase
    private let biometricLoginUseCase: BiometricLoginUseCase
    private let logoutUseCase: LogoutUseCase
    private let sessionRepository: SessionRepositoryProtocol
    private let passwordRecoveryUseCase: PasswordRecoveryUseCase
    private let authRepository: AuthRepository
    private let errorHandler: ErrorHandler
    private let settingsStore: SettingsStore
    private let paymentSyncCoordinator: PaymentSyncCoordinator

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "SessionCoordinator")

    // MARK: - Initialization

    init(
        authRepository: AuthRepository,
        errorHandler: ErrorHandler,
        settingsStore: SettingsStore,
        paymentSyncCoordinator: PaymentSyncCoordinator,
        authDependencyContainer: AuthDependencyContainer
    ) {
        self.authRepository = authRepository
        self.errorHandler = errorHandler
        self.settingsStore = settingsStore
        self.paymentSyncCoordinator = paymentSyncCoordinator

        // Initialize Use Cases from container
        self.loginUseCase = authDependencyContainer.makeLoginUseCase()
        self.registerUseCase = authDependencyContainer.makeRegisterUseCase()
        self.biometricLoginUseCase = authDependencyContainer.makeBiometricLoginUseCase()
        self.logoutUseCase = authDependencyContainer.makeLogoutUseCase()
        self.sessionRepository = authDependencyContainer.makeSessionRepository()
        self.passwordRecoveryUseCase = authDependencyContainer.makePasswordRecoveryUseCase()

        self.isSessionActive = sessionRepository.hasActiveSession

        Task {
            await checkBiometricAvailability()

            let isFaceIDEnabled = settingsStore.isBiometricLockEnabled && canUseBiometrics

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

    // MARK: - Session Lifecycle

    /// Start a new session after successful authentication
    func startSession() async {
        self.isAuthenticated = true
        self.isSessionActive = true
        await sessionRepository.startSession()
        await sessionRepository.updateLastActiveTimestamp()
    }

    /// End current session
    func endSession(inactivity: Bool = false) async {
        self.isAuthenticated = false
        self.isSessionActive = false

        if inactivity {
            self.showInactivityAlert = true
        }
    }

    /// Update last active timestamp (called when user interacts)
    func updateLastActiveTimestamp() {
        Task {
            await sessionRepository.updateLastActiveTimestamp()
        }
    }

    // MARK: - Session Validation

    /// Check session validity and logout if expired (only when online)
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

    /// Check if online and logout only if connected (allows offline work)
    private func checkAndLogoutIfOnline() async {
        logger.info("🔍 Checking if should logout due to inactivity...")

        do {
            try await authRepository.ensureValidSession()
            logger.info("✅ Valid session in Supabase - not logging out")
            await sessionRepository.updateLastActiveTimestamp()
        } catch {
            logger.warning("⚠️ Could not verify session: \(error.localizedDescription)")

            do {
                _ = try await authRepository.authServiceInternal.getCurrentSession()
                // Online but session expired -> logout
                logger.info("🌐 Connection available but session expired - logging out due to inactivity")
                await performLogout(inactivity: true, clearCredentials: true)
            } catch {
                // Offline -> don't logout
                logger.info("📴 No connection - user can continue working offline indefinitely")
            }
        }
    }

    // MARK: - Logout Coordination

    /// Logout - preserves local data
    func logout() async {
        await performLogout(inactivity: false, clearCredentials: !settingsStore.isBiometricLockEnabled)
    }

    /// Unlink device - clears all local data
    func unlinkDevice() async {
        logger.info("🔓 Unlinking device - clearing all local data")

        isLoading = true
        defer { isLoading = false }

        _ = await logoutUseCase.execute()
        _ = await paymentSyncCoordinator.clearLocalDatabase(force: true)

        logger.warning("⚠️ UserProfile cleanup not yet migrated to Clean Architecture")

        _ = KeychainManager.deleteCredentials()
        await sessionRepository.clearSession()

        self.isAuthenticated = false
        self.isSessionActive = false

        logger.info("✅ Device unlinked - all local data removed")
    }

    private func performLogout(inactivity: Bool, clearCredentials: Bool) async {
        logger.info("🚪 Performing logout")

        isLoading = true
        defer { isLoading = false }

        _ = await logoutUseCase.execute()

        if clearCredentials {
            _ = KeychainManager.deleteCredentials()
            KeychainManager.deleteHasLoggedIn()
            logger.info("🗑️ Credentials deleted from Keychain")
        } else {
            logger.info("🔐 Credentials kept in Keychain (biometric enabled)")
        }

        await endSession(inactivity: inactivity)
    }

    // MARK: - Biometric Login Coordination

    /// Perform biometric login
    func authenticateWithBiometrics() async {
        let canUse = await biometricLoginUseCase.canUseBiometricLogin()

        guard canUse else {
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
        case .success:
            await startSession()
            logger.info("✅ Biometric login successful")

        case .failure(let error):
            logger.error("❌ Biometric login failed: \(error.errorCode)")
            errorHandler.handle(error)
        }
    }

    /// Clear biometric credentials
    func clearBiometricCredentials() async {
        KeychainManager.deleteHasLoggedIn()
        _ = KeychainManager.deleteCredentials()
        await sessionRepository.clearSession()

        self.isSessionActive = false
        logger.info("🔐 Credentials removed from Keychain (biometric disabled)")
    }
}
