//
//  AuthDependencyContainer.swift
//  pagosApp
//
//  Dependency Injection Container for Auth module
//  Clean Architecture - DI Layer
//

import Foundation
import Supabase

/// Dependency injection container for Auth module
/// Manages creation and lifecycle of all Auth dependencies
@MainActor
final class AuthDependencyContainer {
    // MARK: - External Dependencies

    private let supabaseClient: SupabaseClient
    private let log: DomainLogWriter

    init(supabaseClient: SupabaseClient, log: DomainLogWriter) {
        self.supabaseClient = supabaseClient
        self.log = log
    }

    // MARK: - Data Sources

    private lazy var authRemoteDataSource: AuthRemoteDataSource = {
        SupabaseAuthDataSource(client: supabaseClient)
    }()

    private lazy var authLocalDataSource: AuthLocalDataSource = {
        KeychainAuthDataSource()
    }()

    private lazy var biometricCredentialsDataSource: BiometricCredentialsDataSource = {
        KeychainBiometricCredentialsDataSource()
    }()

    private lazy var sharedSessionRepository: SessionRepositoryProtocol = SessionRepositoryImpl()

    private lazy var sharedRefreshSessionUseCase: RefreshSessionUseCase = {
        RefreshSessionUseCase(
            authRepository: makeAuthRepository(),
            sessionRepository: makeSessionRepository(),
            log: log
        )
    }()

    // MARK: - Mappers

    private lazy var authDTOMapper: SupabaseAuthDTOMapper = {
        SupabaseAuthDTOMapper()
    }()

    private lazy var sharedAuthRepository: AuthRepositoryProtocol = AuthRepositoryImpl(
        remoteDataSource: authRemoteDataSource,
        localDataSource: authLocalDataSource,
        mapper: authDTOMapper
    )

    // MARK: - Repositories

    func makeAuthRepository() -> AuthRepositoryProtocol {
        sharedAuthRepository
    }

    func makeSessionRepository() -> SessionRepositoryProtocol {
        sharedSessionRepository
    }

    func makeBiometricRepository() -> BiometricRepositoryProtocol {
        BiometricRepositoryImpl()
    }

    // MARK: - Use Cases

    func makeLoginUseCase() -> LoginUseCase {
        LoginUseCase(
            authRepository: makeAuthRepository()
        )
    }

    func makeRegisterUseCase() -> RegisterUseCase {
        RegisterUseCase(
            authRepository: makeAuthRepository()
        )
    }

    func makeLogoutUseCase() -> LogoutUseCase {
        LogoutUseCase(
            authRepository: makeAuthRepository(),
            sessionRepository: makeSessionRepository()
        )
    }

    func makeBiometricLoginUseCase() -> BiometricLoginUseCase {
        BiometricLoginUseCase(
            biometricRepository: makeBiometricRepository(),
            authRepository: makeAuthRepository()
        )
    }

    func makeValidateSessionUseCase() -> ValidateSessionUseCase {
        ValidateSessionUseCase(
            sessionRepository: makeSessionRepository()
        )
    }

    func makeRefreshSessionUseCase() -> RefreshSessionUseCase {
        sharedRefreshSessionUseCase
    }

    func makePasswordRecoveryUseCase() -> PasswordRecoveryUseCase {
        PasswordRecoveryUseCase(
            authRepository: makeAuthRepository()
        )
    }

    func makeGetCurrentUserIdUseCase() -> GetCurrentUserIdUseCase {
        GetCurrentUserIdUseCase(
            authRepository: makeAuthRepository()
        )
    }

    func makeEnsureValidSessionUseCase() -> EnsureValidSessionUseCase {
        EnsureValidSessionUseCase(
            authRepository: makeAuthRepository(),
            refreshSessionUseCase: makeRefreshSessionUseCase(),
            log: log
        )
    }

    func makeGetAuthenticationStatusUseCase() -> GetAuthenticationStatusUseCase {
        GetAuthenticationStatusUseCase(
            authRepository: makeAuthRepository()
        )
    }

    func makeSaveBiometricCredentialsUseCase() -> SaveBiometricCredentialsUseCase {
        SaveBiometricCredentialsUseCase(
            biometricCredentialsDataSource: biometricCredentialsDataSource,
            log: log
        )
    }

    func makeClearBiometricCredentialsUseCase() -> ClearBiometricCredentialsUseCase {
        ClearBiometricCredentialsUseCase(
            biometricCredentialsDataSource: biometricCredentialsDataSource,
            log: log
        )
    }

    func makeHasBiometricCredentialsUseCase() -> HasBiometricCredentialsUseCase {
        HasBiometricCredentialsUseCase(
            biometricCredentialsDataSource: biometricCredentialsDataSource
        )
    }

    func makeUnlinkDeviceUseCase(
        clearLocalDatabaseUseCase: ClearLocalDatabaseUseCase,
        deleteLocalProfileUseCase: DeleteLocalProfileUseCase
    ) -> UnlinkDeviceUseCase {
        UnlinkDeviceUseCase(
            logoutUseCase: makeLogoutUseCase(),
            clearLocalDatabaseUseCase: clearLocalDatabaseUseCase,
            deleteLocalProfileUseCase: deleteLocalProfileUseCase,
            clearBiometricCredentialsUseCase: makeClearBiometricCredentialsUseCase(),
            sessionRepository: makeSessionRepository(),
            log: log
        )
    }

    // MARK: - Coordinators

    func makeSessionCoordinator(
        errorHandler: ErrorHandler,
        settingsStore: SettingsStore,
        paymentSyncCoordinator: PaymentSyncCoordinator,
        reminderSyncCoordinator: ReminderSyncCoordinator
    ) -> SessionCoordinator {
        let coordinateSyncUseCase = CoordinateSyncUseCase(
            paymentSync: paymentSyncCoordinator,
            reminderSync: reminderSyncCoordinator,
            log: log
        )
        return SessionCoordinator(
            errorHandler: errorHandler,
            settingsStore: settingsStore,
            paymentSyncCoordinator: paymentSyncCoordinator,
            reminderSyncCoordinator: reminderSyncCoordinator,
            coordinateSyncUseCase: coordinateSyncUseCase,
            log: log,
            authDependencyContainer: self
        )
    }

    // MARK: - ViewModels

    func makeLoginViewModel() -> LoginViewModel {
        LoginViewModel(
            loginUseCase: makeLoginUseCase(),
            biometricLoginUseCase: makeBiometricLoginUseCase(),
            passwordRecoveryUseCase: makePasswordRecoveryUseCase(),
            hasBiometricCredentialsUseCase: makeHasBiometricCredentialsUseCase()
        )
    }

    func makeRegisterViewModel() -> RegisterViewModel {
        RegisterViewModel(
            registerUseCase: makeRegisterUseCase()
        )
    }

    func makeForgotPasswordViewModel() -> ForgotPasswordViewModel {
        ForgotPasswordViewModel(
            passwordRecoveryUseCase: makePasswordRecoveryUseCase()
        )
    }

    func makeResetPasswordViewModel() -> ResetPasswordViewModel {
        ResetPasswordViewModel(
            passwordRecoveryUseCase: makePasswordRecoveryUseCase()
        )
    }
}
