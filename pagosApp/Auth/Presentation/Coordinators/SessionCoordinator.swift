//
//  SessionCoordinator.swift
//  pagosApp
//
//  Session coordination layer - manages session lifecycle and UI state
//  Clean Architecture - Presentation/Coordination Layer
//

import Foundation
import Observation

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
    private let checkBiometricAvailabilityUseCase: CheckBiometricAvailabilityUseCaseProtocol
    private let verifyRemoteSessionUseCase: VerifyRemoteSessionUseCaseProtocol
    private let coordinateSyncUseCase: CoordinateSyncUseCaseProtocol
    private let errorHandler: ErrorHandler
    private let settingsStore: SettingsStore
    private let paymentSyncCoordinator: PaymentSyncCoordinator
    private let reminderSyncCoordinator: ReminderSyncCoordinator
    private let log: DomainLogWriter

    private static let logCategory = "SessionCoordinator"

    // MARK: - Initialization

    init(
        errorHandler: ErrorHandler,
        settingsStore: SettingsStore,
        paymentSyncCoordinator: PaymentSyncCoordinator,
        reminderSyncCoordinator: ReminderSyncCoordinator,
        coordinateSyncUseCase: CoordinateSyncUseCaseProtocol,
        log: DomainLogWriter,
        authDependencyContainer: AuthDependencyContainer
    ) {
        self.errorHandler = errorHandler
        self.settingsStore = settingsStore
        self.paymentSyncCoordinator = paymentSyncCoordinator
        self.reminderSyncCoordinator = reminderSyncCoordinator
        self.log = log

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
        
        // Initialize new specialized UseCases
        self.checkBiometricAvailabilityUseCase = CheckBiometricAvailabilityUseCase()
        self.verifyRemoteSessionUseCase = VerifyRemoteSessionUseCase(
            getAuthenticationStatusUseCase: authDependencyContainer.makeGetAuthenticationStatusUseCase()
        )
        self.coordinateSyncUseCase = coordinateSyncUseCase

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
        } else if isLocalSessionValid {
            // Has valid local session, no biometric needed - authenticate immediately
            self.isAuthenticated = true
        } else {
            // No session or expired locally - show login
            self.isAuthenticated = false
        }

        // Listen for logout notifications
        Task { [weak self] in
            guard let self else { return }
            for await _ in NotificationCenter.default.notifications(named: NSNotification.Name("UserDidLogout")) {
                self.isAuthenticated = false
                self.isSessionActive = false
            }
        }

        // Background verification and biometric check - with delay to prevent immediate UI changes
        Task {
            guard !hasPerformedInitialCheck else {
                return
            }
            hasPerformedInitialCheck = true

            await checkBiometricAvailability()
            
            // Only proceed with remote verification if user is still supposed to be authenticated
            guard self.isAuthenticated else {
                return
            }

            // Use specialized UseCase for remote session verification
            let verificationResult = await verifyRemoteSessionUseCase.execute(allowNetworkDelay: true)
            
            
            // Handle verification results conservatively
            switch verificationResult {
            case .valid:
                break
            case .invalid:
                // Verify locally before forced logout
                let isLocallyExpired = await sessionRepository.isSessionExpired()
                
                if isLocallyExpired {
                    log.warning("⚠️ Session expired both locally and remotely - logging out", category: Self.logCategory)
                    self.isAuthenticated = false
                    self.isSessionActive = false
                } else {
                    break
                }
            case .networkError:
                break
            case .timeout:
                break
            }
        }
    }

    private func checkBiometricAvailability() async {
        // Use specialized UseCase for biometric availability check
        self.canUseBiometrics = await checkBiometricAvailabilityUseCase.execute()

        #if targetEnvironment(simulator)
        canUseBiometrics = true
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
        let userInfo: [String: Any]?
        if let userId = userId {
            userInfo = ["userId": userId]
        } else {
            userInfo = nil
        }
        
        NotificationCenter.default.post(
            name: NSNotification.Name("UserDidLogin"),
            object: nil,
            userInfo: userInfo
        )

        // Use specialized UseCase for sync coordination (non-blocking)
        Task.detached { @MainActor in
            await self.coordinateSyncUseCase.handlePostLoginSync()
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
                await checkAndLogoutIfOnline()
            } else {
                await sessionRepository.updateLastActiveTimestamp()
            }

        case .failure(let error):
            if error == .sessionExpired {
                log.warning("⏰ Session expired - checking if should logout", category: Self.logCategory)
                await checkAndLogoutIfOnline()
            }
        }
    }

    /// Check if online and logout only if connected (allows offline work)
    private func checkAndLogoutIfOnline() async {
        do {
            // Use Use Case to ensure valid session (Clean Architecture)
            try await ensureValidSessionUseCase.execute()
            await sessionRepository.updateLastActiveTimestamp()
        } catch {
            log.warning("⚠️ Could not verify session: \(error.localizedDescription)", category: Self.logCategory)

            // Check if we're online by attempting to get current session
            let isAuthenticated = await getAuthenticationStatusUseCase.execute()

            if isAuthenticated {
                // Online but session expired -> logout
                await performLogout(inactivity: true, clearCredentials: true)
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
        isLoading = true
        defer { isLoading = false }

        _ = await logoutUseCase.execute()
        _ = await paymentSyncCoordinator.clearLocalDatabase(force: true)
        _ = await reminderSyncCoordinator.clearLocalDatabase(force: true)

        log.warning("⚠️ UserProfile cleanup not yet migrated to Clean Architecture", category: Self.logCategory)

        _ = clearBiometricCredentialsUseCase.execute()
        await sessionRepository.clearSession()

        self.isAuthenticated = false
        self.isSessionActive = false
    }

    private func performLogout(inactivity: Bool, clearCredentials: Bool) async {
        isLoading = true
        defer { isLoading = false }

        _ = await logoutUseCase.execute()

        if clearCredentials {
            _ = clearBiometricCredentialsUseCase.execute()
        }

        await endSession(inactivity: inactivity)
    }

    // MARK: - Biometric Login Coordination

    /// Perform biometric login
    func authenticateWithBiometrics() async {
        let canUse = await biometricLoginUseCase.canUseBiometricLogin()

        guard canUse else {
            log.warning("⚠️ Biometrics not available", category: Self.logCategory)
            return
        }

        guard hasBiometricCredentialsUseCase.execute() else {
            log.warning("⚠️ No credentials stored in Keychain for biometric login", category: Self.logCategory)
            return
        }

        // No loading indicator - Face ID shows its own system UI
        let result = await biometricLoginUseCase.execute()

        switch result {
        case .success:
            await startSession()

        case .failure(let error):
            log.error("❌ Biometric login failed: \(error.errorCode)", category: Self.logCategory)
            errorHandler.handle(error)
        }
    }

    /// Clear biometric credentials
    func clearBiometricCredentials() async {
        _ = clearBiometricCredentialsUseCase.execute()
        await sessionRepository.clearSession()

        self.isSessionActive = false
    }

    /// Check if biometric credentials are stored
    func hasBiometricCredentials() -> Bool {
        return hasBiometricCredentialsUseCase.execute()
    }
}
