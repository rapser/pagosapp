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
    private let paymentSync: PaymentSyncCoordinating
    private let reminderSync: ReminderSyncCoordinating
    private let log: DomainLogWriter

    private static let logCategory = "SessionCoordinator"

    // MARK: - Initialization

    init(
        errorHandler: ErrorHandler,
        settingsStore: SettingsStore,
        paymentSync: PaymentSyncCoordinating,
        reminderSync: ReminderSyncCoordinating,
        coordinateSyncUseCase: CoordinateSyncUseCaseProtocol,
        log: DomainLogWriter,
        authDependencyContainer: AuthDependencyContainer
    ) {
        self.errorHandler = errorHandler
        self.settingsStore = settingsStore
        self.paymentSync = paymentSync
        self.reminderSync = reminderSync
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
        let hasCredentials = hasBiometricCredentialsUseCase.execute()

        #if targetEnvironment(simulator)
        self.canUseBiometrics = true
        #endif

        self.isAuthenticated = Self.computeInitialIsAuthenticated(
            settingsStore: settingsStore,
            sessionRepository: sessionRepository,
            hasCredentials: hasCredentials,
            isSessionActive: isSessionActive
        )

        observeLogoutNotifications()
        scheduleInitialRemoteVerification()
    }

    private static func computeInitialIsAuthenticated(
        settingsStore: SettingsStore,
        sessionRepository: SessionRepositoryProtocol,
        hasCredentials: Bool,
        isSessionActive: Bool
    ) -> Bool {
        let isLocalSessionValid = isSessionActive && !sessionRepository.isSessionExpiredSync
        let shouldShowBiometric = settingsStore.isBiometricLockEnabled && hasCredentials && isLocalSessionValid
        if shouldShowBiometric {
            return false
        }
        if isLocalSessionValid {
            return true
        }
        return false
    }

    private func observeLogoutNotifications() {
        Task { [weak self] in
            guard let self else { return }
            for await _ in NotificationCenter.default.notifications(named: NSNotification.Name("UserDidLogout")) {
                self.isAuthenticated = false
                self.isSessionActive = false
            }
        }
    }

    private func scheduleInitialRemoteVerification() {
        Task { @MainActor in
            guard !hasPerformedInitialCheck else {
                return
            }
            hasPerformedInitialCheck = true

            await checkBiometricAvailability()

            guard self.isAuthenticated else {
                return
            }

            let verificationResult = await verifyRemoteSessionUseCase.execute(allowNetworkDelay: true)
            await handleInitialVerificationResult(verificationResult)
        }
    }

    private func handleInitialVerificationResult(_ verificationResult: SessionVerificationResult) async {
        switch verificationResult {
        case .valid, .networkError, .timeout:
            break
        case .invalid:
            let isLocallyExpired = await sessionRepository.isSessionExpired()
            if isLocallyExpired {
                log.warning("⚠️ Session expired both locally and remotely - logging out", category: Self.logCategory)
                isAuthenticated = false
                isSessionActive = false
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
        Task { @MainActor in
            await coordinateSyncUseCase.handlePostLoginSync()
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
        _ = await paymentSync.clearLocalDatabase(force: true)
        _ = await reminderSync.clearLocalDatabase(force: true)

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
