//
//  ResetPasswordViewModel.swift
//  pagosApp
//
//  Created by miguel tomairo on 1/12/25.
//  Modern iOS 18+ using @Observable macro
//

import Foundation
import Observation

@MainActor
@Observable
final class ResetPasswordViewModel {

    var newPassword: String = ""
    var confirmPassword: String = ""
    var isLoading: Bool = false
    var didResetPassword: Bool = false
    var errorMessage: String?

    private let passwordRecoveryUseCase: PasswordRecoveryUseCase

    init(passwordRecoveryUseCase: PasswordRecoveryUseCase) {
        self.passwordRecoveryUseCase = passwordRecoveryUseCase
    }

    func resetPassword(accessToken: String, refreshToken: String) {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                try await passwordRecoveryUseCase.resetPassword(accessToken: accessToken, refreshToken: refreshToken, newPassword: newPassword)
                didResetPassword = true
            } catch {
                errorMessage = "Error al restablecer la contraseña. Inténtalo de nuevo."
            }
            isLoading = false
        }
    }
}