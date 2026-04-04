//
//  ResetPasswordViewModel.swift
//  pagosApp
//
//  ViewModel for Reset Password screen
//  Clean Architecture - Presentation Layer
//

import Foundation

@MainActor
@Observable
final class ResetPasswordViewModel: BaseViewModel {
    // MARK: - UI State

    var newPassword: String = ""
    var confirmPassword: String = ""
    var showPassword: Bool = false
    var showConfirmPassword: Bool = false
    var didResetPassword: Bool = false

    // MARK: - Dependencies (Use Cases)

    private let passwordRecoveryUseCase: PasswordRecoveryUseCase

    // MARK: - Initialization

    init(passwordRecoveryUseCase: PasswordRecoveryUseCase) {
        self.passwordRecoveryUseCase = passwordRecoveryUseCase
        super.init(category: "ResetPasswordViewModel")
    }

    // MARK: - Actions

    func resetPassword(token: String) async {
        guard !isLoading else { return }
        logDebug("Attempting to reset password")

        guard newPassword == confirmPassword else {
            setValidationError("Las contraseñas no coinciden")
            return
        }

        guard isPasswordStrong else {
            setValidationError("La contraseña debe tener al menos 6 caracteres")
            return
        }

        await withLoadingAndErrorHandling(
            operation: {
                let result = await self.passwordRecoveryUseCase.resetPassword(
                    token: token,
                    newPassword: self.newPassword
                )
                
                switch result {
                case .success:
                    self.didResetPassword = true
                    self.logDebug("Password reset successfully")
                    return true
                case .failure(let error):
                    self.logDebug("Reset password failed: \(error.errorCode)")
                    throw error
                }
            },
            onError: { _ in
                self.setError("Error al restablecer la contraseña. Inténtalo de nuevo.")
            }
        )
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
        PasswordValidator.isValid(newPassword)
    }
}
