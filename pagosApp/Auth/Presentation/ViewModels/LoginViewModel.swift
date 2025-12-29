//
//  LoginViewModel.swift
//  pagosApp
//
//  ViewModel for Login screen
//  Clean Architecture - Presentation Layer
//

import Foundation
import Observation
import OSLog

private let logger = Logger(subsystem: "com.rapser.pagosApp", category: "LoginViewModel")

/// ViewModel for Login screen using Clean Architecture
@MainActor
@Observable
final class LoginViewModel {
    // MARK: - UI State

    var email: String = ""
    var password: String = ""
    var rememberMe: Bool = false
    var showPassword: Bool = false
    var isLoading: Bool = false
    var errorMessage: String?
    var showError: Bool = false
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
    }

    // MARK: - Actions

    /// Login with email and password
    func login() async {
        guard !isLoading else { return }

        logger.info("🔑 Attempting login")

        isLoading = true
        errorMessage = nil
        showError = false
        defer { isLoading = false }

        let result = await loginUseCase.execute(email: email, password: password)

        switch result {
        case .success(let session):
            logger.info("✅ Login successful")
            onLoginSuccess?(session)

        case .failure(let error):
            logger.error("❌ Login failed: \(error.errorCode)")
            errorMessage = mapErrorToUserMessage(error)
            showError = true
        }
    }

    /// Login with biometric (Face ID/Touch ID)
    func loginWithBiometric() async {
        guard !isLoading else { return }

        logger.info("🔐 Attempting biometric login")

        isLoading = true
        errorMessage = nil
        showError = false
        defer { isLoading = false }

        let result = await biometricLoginUseCase.execute()

        switch result {
        case .success(let session):
            logger.info("✅ Biometric login successful")
            onLoginSuccess?(session)

        case .failure(let error):
            logger.error("❌ Biometric login failed: \(error.errorCode)")
            errorMessage = mapErrorToUserMessage(error)
            showError = true
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

    // MARK: - Error Mapping

    private func mapErrorToUserMessage(_ error: AuthError) -> String {
        switch error {
        case .invalidCredentials:
            return "Email o contraseña incorrectos"
        case .invalidEmail:
            return "Email inválido"
        case .weakPassword:
            return "La contraseña debe tener al menos 6 caracteres"
        case .networkError:
            return "Error de conexión. Verifica tu internet"
        case .sessionExpired:
            return "Sesión expirada. Vuelve a iniciar sesión"
        case .userNotFound:
            return "Usuario no encontrado"
        case .emailAlreadyExists:
            return "El email ya está registrado"
        case .unknown(let message):
            return message
        }
    }
}
