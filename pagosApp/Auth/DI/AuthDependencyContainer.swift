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

    init(supabaseClient: SupabaseClient) {
        self.supabaseClient = supabaseClient
    }

    // MARK: - Data Sources

    private lazy var authRemoteDataSource: AuthRemoteDataSource = {
        SupabaseAuthDataSource(client: supabaseClient)
    }()

    private lazy var authLocalDataSource: AuthLocalDataSource = {
        KeychainAuthDataSource()
    }()

    // MARK: - Mappers

    private lazy var authDTOMapper: SupabaseAuthDTOMapper = {
        SupabaseAuthDTOMapper()
    }()

    // MARK: - Repositories

    func makeAuthRepository() -> AuthRepositoryProtocol {
        AuthRepositoryImpl(
            remoteDataSource: authRemoteDataSource,
            localDataSource: authLocalDataSource,
            mapper: authDTOMapper
        )
    }

    func makeSessionRepository() -> SessionRepositoryProtocol {
        SessionRepositoryImpl()
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
        RefreshSessionUseCase(
            authRepository: makeAuthRepository(),
            sessionRepository: makeSessionRepository()
        )
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

    // MARK: - Coordinators

    func makeSessionCoordinator(
        errorHandler: ErrorHandler,
        settingsStore: SettingsStore,
        paymentSyncCoordinator: PaymentSyncCoordinator
    ) -> SessionCoordinator {
        // Legacy AuthRepository for compatibility (to be removed in future phases)
        let authAdapter = SupabaseAuthAdapter(client: supabaseClient)
        let authRepository = AuthRepository(authService: authAdapter)

        return SessionCoordinator(
            authRepository: authRepository,
            errorHandler: errorHandler,
            settingsStore: settingsStore,
            paymentSyncCoordinator: paymentSyncCoordinator,
            authDependencyContainer: self
        )
    }

    // MARK: - ViewModels

    func makeLoginViewModel() -> LoginViewModel {
        LoginViewModel(
            loginUseCase: makeLoginUseCase(),
            biometricLoginUseCase: makeBiometricLoginUseCase(),
            passwordRecoveryUseCase: makePasswordRecoveryUseCase()
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
