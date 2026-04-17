//
//  ForgotPasswordViewModel.swift
//  pagosApp
//
//  ViewModel for Forgot Password screen
//  Clean Architecture - Presentation Layer
//

import Foundation

@MainActor
@Observable
final class ForgotPasswordViewModel: BaseViewModel {
    // MARK: - UI State

    var email: String = ""
    var didSendResetLink: Bool = false

    // MARK: - Dependencies (Use Cases)

    private let passwordRecoveryUseCase: PasswordRecoveryUseCase

    // MARK: - Initialization

    init(passwordRecoveryUseCase: PasswordRecoveryUseCase) {
        self.passwordRecoveryUseCase = passwordRecoveryUseCase
        super.init(category: "ForgotPasswordViewModel")
    }

    // MARK: - Actions

    func sendPasswordReset() async {
        guard !isLoading else { return }
        logDebug("Attempting to send password reset email")

        await withLoadingAndErrorHandling(
            operation: {
                let result = await self.passwordRecoveryUseCase.sendPasswordReset(email: self.email)
                
                switch result {
                case .success:
                    self.didSendResetLink = true
                    self.logDebug("Password reset email sent successfully")
                    return true
                case .failure(let error):
                    self.logDebug("Send password reset failed: \(error.errorCode)")
                    throw error
                }
            },
            onError: { _ in
                self.setError(L10n.Auth.ForgotPassword.sendFailed)
            }
        )
    }

    // MARK: - Validation

    var isFormValid: Bool {
        !email.isEmpty && EmailValidator.isValid(email)
    }

    var isEmailValid: Bool {
        EmailValidator.isValid(email)
    }
}
