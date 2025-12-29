//
//  ForgotPasswordViewModel.swift
//  pagosApp
//
//  ViewModel for Forgot Password screen
//  Clean Architecture - Presentation Layer
//

import Foundation
import Observation
import OSLog

private let logger = Logger(subsystem: "com.rapser.pagosApp", category: "ForgotPasswordViewModel")

@MainActor
@Observable
final class ForgotPasswordViewModel {
    // MARK: - UI State

    var email: String = ""
    var isLoading: Bool = false
    var didSendResetLink: Bool = false
    var errorMessage: String?
    var showError: Bool = false

    // MARK: - Dependencies (Use Cases)

    private let passwordRecoveryUseCase: PasswordRecoveryUseCase

    // MARK: - Initialization

    init(passwordRecoveryUseCase: PasswordRecoveryUseCase) {
        self.passwordRecoveryUseCase = passwordRecoveryUseCase
    }

    // MARK: - Actions

    func sendPasswordReset() async {
        guard !isLoading else { return }

        logger.info("📧 Attempting to send password reset email")

        isLoading = true
        errorMessage = nil
        showError = false
        defer { isLoading = false }

        let result = await passwordRecoveryUseCase.sendPasswordReset(email: email)

        switch result {
        case .success:
            didSendResetLink = true
            logger.info("✅ Password reset email sent successfully")
        case .failure(let error):
            logger.error("❌ Failed to send password reset email: \(error.errorCode)")
            errorMessage = "Error al enviar el correo de restablecimiento. Inténtalo de nuevo."
            showError = true
        }
    }

    // MARK: - Validation

    var isFormValid: Bool {
        !email.isEmpty
    }
}
