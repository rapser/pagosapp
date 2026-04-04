//
//  LoginViewModel.swift
//  pagosApp
//
//  ViewModel for Login screen
//  Clean Architecture - Presentation Layer
//

import Foundation

/// ViewModel for Login screen using Clean Architecture
@MainActor
@Observable
final class LoginViewModel: BaseViewModel {
    // MARK: - UI State

    var email: String = ""
    var password: String = ""
    var rememberMe: Bool = false
    var showPassword: Bool = true  // Por defecto la contraseña está oculta (solo puntos)
    var canUseBiometric: Bool = false
    var biometricType: BiometricType = .none

    // MARK: - Dependencies (Use Cases)

    private let loginUseCase: LoginUseCase
    private let biometricLoginUseCase: BiometricLoginUseCase
    private let passwordRecoveryUseCase: PasswordRecoveryUseCase
    private let hasBiometricCredentialsUseCase: HasBiometricCredentialsUseCase

    // MARK: - Callbacks

    var onLoginSuccess: ((AuthSession) -> Void)?

    // MARK: - Initialization

    init(
        loginUseCase: LoginUseCase,
        biometricLoginUseCase: BiometricLoginUseCase,
        passwordRecoveryUseCase: PasswordRecoveryUseCase,
        hasBiometricCredentialsUseCase: HasBiometricCredentialsUseCase
    ) {
        self.loginUseCase = loginUseCase
        self.biometricLoginUseCase = biometricLoginUseCase
        self.passwordRecoveryUseCase = passwordRecoveryUseCase
        self.hasBiometricCredentialsUseCase = hasBiometricCredentialsUseCase
        super.init(category: "LoginViewModel")
    }

    // MARK: - Actions

    /// Login with email and password
    func login() async {
        guard !isLoading else { return }
        logDebug("Attempting login")

        isLoading = true
        clearError()

        let result = await loginUseCase.execute(email: email, password: password)

        switch result {
        case .success(let session):
            logDebug("Login successful")
            // Keep isLoading = true until navigation completes
            // LoginView will disappear when SessionCoordinator sets isAuthenticated = true
            onLoginSuccess?(session)
            // Note: isLoading stays true - prevents flash of login button before home appears

        case .failure(let error):
            logDebug("Login failed: \(error.errorCode)")
            setError(AuthErrorMessageMapper.message(for: error))
            isLoading = false
        }
    }

    /// Login with biometric (Face ID/Touch ID)
    func loginWithBiometric() async {
        guard !isLoading else { return }
        logDebug("Attempting biometric login")

        isLoading = true
        clearError()

        let result = await biometricLoginUseCase.execute()

        switch result {
        case .success(let session):
            logDebug("Biometric login successful")
            // Keep isLoading = true until navigation completes
            // LoginView will disappear when SessionCoordinator sets isAuthenticated = true
            onLoginSuccess?(session)
            // Note: isLoading stays true - prevents flash of login button before home appears

        case .failure(let error):
            logDebug("Biometric login failed: \(error.errorCode)")
            setError(AuthErrorMessageMapper.message(for: error))
            isLoading = false
        }
    }

    /// Check if biometric login is available
    func canUseBiometricLogin() async -> Bool {
        let canUse = await biometricLoginUseCase.canUseBiometricLogin()
        canUseBiometric = canUse
        return canUse
    }

    /// Get biometric type available
    func getBiometricType() async -> BiometricType {
        let type = await biometricLoginUseCase.getBiometricType()
        biometricType = type
        return type
    }

    /// Check if biometric credentials are stored
    func hasBiometricCredentials() -> Bool {
        return hasBiometricCredentialsUseCase.execute()
    }

    /// Get PasswordRecoveryUseCase for ForgotPasswordView
    func getPasswordRecoveryUseCase() -> PasswordRecoveryUseCase {
        passwordRecoveryUseCase
    }

    // MARK: - Validation

    var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty
    }
}
