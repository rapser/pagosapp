//
//  ResetPasswordViewModel.swift
//  pagosApp
//
//  ViewModel for Reset Password screen
//  Clean Architecture - Presentation Layer
//

import Foundation
import Observation
import OSLog

private let logger = Logger(subsystem: "com.rapser.pagosApp", category: "ResetPasswordViewModel")

@MainActor
@Observable
final class ResetPasswordViewModel {
    // MARK: - UI State

    var newPassword: String = ""
    var confirmPassword: String = ""
    var showPassword: Bool = false
    var showConfirmPassword: Bool = false
    var isLoading: Bool = false
    var didResetPassword: Bool = false
    var errorMessage: String?
    var showError: Bool = false

    // MARK: - Dependencies (Use Cases)

    private let passwordRecoveryUseCase: PasswordRecoveryUseCase

    // MARK: - Initialization

    init(passwordRecoveryUseCase: PasswordRecoveryUseCase) {
        self.passwordRecoveryUseCase = passwordRecoveryUseCase
    }

    // MARK: - Actions

    func resetPassword(token: String) async {
        guard !isLoading else { return }

        logger.info("🔐 Attempting to reset password")

        // Validate passwords match
        guard newPassword == confirmPassword else {
            errorMessage = "Las contraseñas no coinciden"
            showError = true
            return
        }

        // Validate password strength
        guard isPasswordStrong else {
            errorMessage = "La contraseña debe tener al menos 6 caracteres"
            showError = true
            return
        }

        isLoading = true
        errorMessage = nil
        showError = false
        defer { isLoading = false }

        let result = await passwordRecoveryUseCase.resetPassword(
            token: token,
            newPassword: newPassword
        )

        switch result {
        case .success:
            didResetPassword = true
            logger.info("✅ Password reset successfully")
        case .failure(let error):
            logger.error("❌ Failed to reset password: \(error.errorCode)")
            errorMessage = "Error al restablecer la contraseña. Inténtalo de nuevo."
            showError = true
        }
    }

    // MARK: - Validation

    var isFormValid: Bool {
        !newPassword.isEmpty &&
        !confirmPassword.isEmpty &&
        newPassword == confirmPassword &&
        isPasswordStrong
    }

    var passwordsMatch: Bool {
        newPassword == confirmPassword
    }

    var isPasswordStrong: Bool {
        newPassword.count >= 6
    }
}