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
    private let getCurrentUserIdUseCase: GetCurrentUserIdUseCase
    private let clearBiometricCredentialsUseCase: ClearBiometricCredentialsUseCase
    private let hasBiometricCredentialsUseCase: HasBiometricCredentialsUseCase
    private let errorHandler: ErrorHandler
    private let settingsStore: SettingsStore
    private let paymentSyncCoordinator: PaymentSyncCoordinator
    private let reminderSyncCoordinator: ReminderSyncCoordinator

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "SessionCoordinator")

    // MARK: - Initialization

    init(
        errorHandler: ErrorHandler,
        settingsStore: SettingsStore,
        paymentSyncCoordinator: PaymentSyncCoordinator,
        reminderSyncCoordinator: ReminderSyncCoordinator,
        authDependencyContainer: AuthDependencyContainer
    ) {
        self.errorHandler = errorHandler
        self.settingsStore = settingsStore
        self.paymentSyncCoordinator = paymentSyncCoordinator
        self.reminderSyncCoordinator = reminderSyncCoordinator

        // Initialize Use Cases from container (Clean Architecture)
        self.loginUseCase = authDependencyContainer.makeLoginUseCase()
        self.registerUseCase = authDependencyContainer.makeRegisterUseCase()
        self.biometricLoginUseCase = authDependencyContainer.makeBiometricLoginUseCase()
        self.logoutUseCase = authDependencyContainer.makeLogoutUseCase()
        self.sessionRepository = authDependencyContainer.makeSessionRepository()
        self.passwordRecoveryUseCase = authDependencyContainer.makePasswordRecoveryUseCase()
        self.ensureValidSessionUseCase = authDependencyContainer.makeEnsureValidSessionUseCase()
        self.getAuthenticationStatusUseCase = authDependencyContainer.makeGetAuthenticationStatusUseCase()
        self.getCurrentUserIdUseCase = authDependencyContainer.makeGetCurrentUserIdUseCase()
        self.clearBiometricCredentialsUseCase = authDependencyContainer.makeClearBiometricCredentialsUseCase()
        self.hasBiometricCredentialsUseCase = authDependencyContainer.makeHasBiometricCredentialsUseCase()

        self.isSessionActive = sessionRepository.hasActiveSession

        // IMPORTANT: Initialize isAuthenticated synchronously to avoid flash of login screen
        // More robust session validation - check both existence AND local expiration
        let hasCredentials = hasBiometricCredentialsUseCase.execute()
        
        #if targetEnvironment(simulator)
        self.canUseBiometrics = true
        #endif
        
        // Improved logic: verify session is both active AND not locally expired
        let isLocalSessionValid = isSessionActive && !sessionRepository.isSessionExpiredSync
        let shouldShowBiometric = settingsStore.isBiometricLockEnabled && hasCredentials && isLocalSessionValid

        if shouldShowBiometric {
            // User is logged in but needs Face ID unlock
            self.isAuthenticated = false
            logger.info("🔐 Init: Biometric lock enabled - will show Face ID screen")
        } else if isLocalSessionValid {
            // Has valid local session, no biometric needed - authenticate immediately
            self.isAuthenticated = true
            logger.info("✅ Init: Valid local session - authenticated immediately (no flash)")
        } else {
            // No session or expired locally - show login
            self.isAuthenticated = false
            if isSessionActive && sessionRepository.isSessionExpiredSync {
                logger.info("📱 Init: Session expired locally - showing login screen")
            } else {
                logger.info("📱 Init: No active session - showing login screen")
            }
        }

        // Listen for logout notifications
        Task {
            for await _ in NotificationCenter.default.notifications(named: NSNotification.Name("UserDidLogout")) {
                logger.info("📢 Received UserDidLogout notification - updating UI state")
                self.isAuthenticated = false
                self.isSessionActive = false
            }
        }

        // Background verification and biometric check - with delay to prevent immediate UI changes
        Task {
            guard !hasPerformedInitialCheck else {
                logger.debug("⏭️ Skipping duplicate initial check")
                return
            }
            hasPerformedInitialCheck = true

            await checkBiometricAvailability()
            
            // Add minimum delay to prevent immediate UI changes after startup
            // This allows the UI to settle before potentially changing authentication state
            try? await Task.sleep(for: .seconds(1.5))

            // Only proceed with remote verification if user is still supposed to be authenticated
            guard self.isAuthenticated else {
                logger.debug("🔍 Skipping remote check - user not authenticated")
                return
            }

            // Verify session remotely (background check - conservative approach)
            let hasActiveSession = await getAuthenticationStatusUseCase.execute()
            
            logger.debug("🔍 Background check - Local session: \(self.isSessionActive), Remote session: \(hasActiveSession)")
            
            // More conservative logout logic - only logout if clearly expired AND we've been authenticated for a while
            if !hasActiveSession && self.isAuthenticated {
                // Double-check locally before forcing logout
                let isLocallyExpired = await sessionRepository.isSessionExpired()
                
                if isLocallyExpired {
                    logger.warning("⚠️ Session expired both locally and remotely - logging out")
                    self.isAuthenticated = false
                    self.isSessionActive = false
                } else {
                    // Remote check failed but local session is valid - might be network issue
                    logger.info("ℹ️ Remote session check failed but local session valid - keeping authenticated")
                }
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

        // Get current user ID to include in notification
        let userId = await getCurrentUserIdUseCase.execute()

        // Notify that user logged in - other features can react (e.g., fetch user profile)
        // This respects Clean Architecture by not creating direct dependencies between features
        NotificationCenter.default.post(
            name: NSNotification.Name("UserDidLogin"),
            object: nil,
            userInfo: userId != nil ? ["userId": userId!] : nil
        )
        logger.info("📢 Posted UserDidLogin notification with userId: \(userId?.uuidString ?? "nil")")

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
        _ = await reminderSyncCoordinator.clearLocalDatabase(force: true)

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

        // No loading indicator - Face ID shows its own system UI
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
