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

    // MARK: - Internal State

    private var hasPerformedInitialCheck = false

    // MARK: - Dependencies (Use Cases only - Clean Architecture)

    private let loginUseCase: LoginUseCase
    private let registerUseCase: RegisterUseCase
    private let biometricLoginUseCase: BiometricLoginUseCase
    private let logoutUseCase: LogoutUseCase
    private let sessionRepository: SessionRepositoryProtocol
    private let passwordRecoveryUseCase: PasswordRecoveryUseCase
    private let ensureValidSessionUseCase: EnsureValidSessionUseCase
    private let getAuthenticationStatusUseCase: GetAuthenticationStatusUseCase
    private let clearBiometricCredentialsUseCase: ClearBiometricCredentialsUseCase
    private let hasBiometricCredentialsUseCase: HasBiometricCredentialsUseCase
    private let errorHandler: ErrorHandler
    private let settingsStore: SettingsStore
    private let paymentSyncCoordinator: PaymentSyncCoordinator

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "SessionCoordinator")

    // MARK: - Initialization

    init(
        errorHandler: ErrorHandler,
        settingsStore: SettingsStore,
        paymentSyncCoordinator: PaymentSyncCoordinator,
        authDependencyContainer: AuthDependencyContainer
    ) {
        self.errorHandler = errorHandler
        self.settingsStore = settingsStore
        self.paymentSyncCoordinator = paymentSyncCoordinator

        // Initialize Use Cases from container (Clean Architecture)
        self.loginUseCase = authDependencyContainer.makeLoginUseCase()
        self.registerUseCase = authDependencyContainer.makeRegisterUseCase()
        self.biometricLoginUseCase = authDependencyContainer.makeBiometricLoginUseCase()
        self.logoutUseCase = authDependencyContainer.makeLogoutUseCase()
        self.sessionRepository = authDependencyContainer.makeSessionRepository()
        self.passwordRecoveryUseCase = authDependencyContainer.makePasswordRecoveryUseCase()
        self.ensureValidSessionUseCase = authDependencyContainer.makeEnsureValidSessionUseCase()
        self.getAuthenticationStatusUseCase = authDependencyContainer.makeGetAuthenticationStatusUseCase()
        self.clearBiometricCredentialsUseCase = authDependencyContainer.makeClearBiometricCredentialsUseCase()
        self.hasBiometricCredentialsUseCase = authDependencyContainer.makeHasBiometricCredentialsUseCase()

        self.isSessionActive = sessionRepository.hasActiveSession

        // Initialize to false until we verify
        self.isAuthenticated = false

        Task {
            // Only perform initial check once
            guard !hasPerformedInitialCheck else {
                logger.debug("⏭️ Skipping duplicate initial check")
                return
            }
            hasPerformedInitialCheck = true

            await checkBiometricAvailability()

            // Check if there's an active authenticated session
            let hasActiveSession = await getAuthenticationStatusUseCase.execute()

            // Check if biometric is enabled AND credentials exist AND has active session
            let hasCredentials = hasBiometricCredentialsUseCase.execute()

            logger.info("🔐 Biometric check - Settings: \(settingsStore.isBiometricLockEnabled), CanUse: \(self.canUseBiometrics), HasCreds: \(hasCredentials), HasSession: \(hasActiveSession)")

            let shouldShowBiometric = settingsStore.isBiometricLockEnabled && canUseBiometrics && hasCredentials && hasActiveSession

            if shouldShowBiometric {
                // Show Face ID lock screen (user is logged in but needs to unlock)
                logger.info("✅ Showing Face ID lock screen")
                self.isAuthenticated = false
            } else if hasActiveSession {
                // Has session but no biometric - already authenticated
                logger.info("✅ Has active session without biometric - authenticated")
                self.isAuthenticated = true
            } else {
                // No session - show login screen
                logger.info("📱 No active session - showing login screen")
                self.isAuthenticated = false
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

        // Sync payments in background (non-blocking)
        // User will see local SwiftData immediately, sync updates in background
        Task.detached { @MainActor in
            self.logger.info("🔄 Starting background sync after login")
            try? await self.paymentSyncCoordinator.performSync()
        }
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
            // Use Use Case to ensure valid session (Clean Architecture)
            try await ensureValidSessionUseCase.execute()
            logger.info("✅ Valid session in backend - not logging out")
            await sessionRepository.updateLastActiveTimestamp()
        } catch {
            logger.warning("⚠️ Could not verify session: \(error.localizedDescription)")

            // Check if we're online by attempting to get current session
            let isAuthenticated = await getAuthenticationStatusUseCase.execute()

            if isAuthenticated {
                // Online but session expired -> logout
                logger.info("🌐 Connection available but session expired - logging out due to inactivity")
                await performLogout(inactivity: true, clearCredentials: true)
            } else {
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

        _ = clearBiometricCredentialsUseCase.execute()
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
            _ = clearBiometricCredentialsUseCase.execute()
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

        guard hasBiometricCredentialsUseCase.execute() else {
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
        _ = clearBiometricCredentialsUseCase.execute()
        await sessionRepository.clearSession()

        self.isSessionActive = false
        logger.info("🔐 Credentials removed from Keychain (biometric disabled)")
    }

    /// Check if biometric credentials are stored
    func hasBiometricCredentials() -> Bool {
        return hasBiometricCredentialsUseCase.execute()
    }
}
