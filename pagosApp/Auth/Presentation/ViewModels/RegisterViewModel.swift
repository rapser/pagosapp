//
//  RegisterViewModel.swift
//  pagosApp
//
//  ViewModel for Registration screen
//  Clean Architecture - Presentation Layer
//

import Foundation
import Observation
import OSLog

private let logger = Logger(subsystem: "com.rapser.pagosApp", category: "RegisterViewModel")

/// ViewModel for Registration screen using Clean Architecture
@MainActor
@Observable
final class RegisterViewModel {
    // MARK: - UI State

    var email: String = ""
    var password: String = ""
    var confirmPassword: String = ""
    var showPassword: Bool = false
    var showConfirmPassword: Bool = false
    var isLoading: Bool = false
    var errorMessage: String?
    var showError: Bool = false

    // MARK: - Dependencies (Use Cases)

    private let registerUseCase: RegisterUseCase

    // MARK: - Callbacks

    var onRegistrationSuccess: ((AuthSession) -> Void)?

    // MARK: - Initialization

    init(registerUseCase: RegisterUseCase) {
        self.registerUseCase = registerUseCase
    }

    // MARK: - Actions

    /// Register new user
    func register() async {
        guard !isLoading else { return }

        logger.info("📝 Attempting registration")

        // Validate passwords match
        guard password == confirmPassword else {
            errorMessage = "Las contraseñas no coinciden"
            showError = true
            return
        }

        isLoading = true
        errorMessage = nil
        showError = false
        defer { isLoading = false }

        let result = await registerUseCase.execute(
            email: email,
            password: password,
            metadata: nil
        )

        switch result {
        case .success(let session):
            logger.info("✅ Registration successful")
            onRegistrationSuccess?(session)

        case .failure(let error):
            logger.error("❌ Registration failed: \(error.errorCode)")
            errorMessage = mapErrorToUserMessage(error)
            showError = true
        }
    }

    // MARK: - Validation

    var isFormValid: Bool {
        !email.isEmpty &&
        !password.isEmpty &&
        !confirmPassword.isEmpty &&
        password == confirmPassword &&
        PasswordValidator.isValid(password)
    }

    var passwordsMatch: Bool {
        password == confirmPassword
    }

    var isPasswordStrong: Bool {
        PasswordValidator.isValid(password)
    }

    // MARK: - Error Mapping (Auth module mapper)

    private func mapErrorToUserMessage(_ error: AuthError) -> String {
        AuthErrorMessageMapper.message(for: error)
    }
}
