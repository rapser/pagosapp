//
//  ForgotPasswordViewModel.swift
//  pagosApp
//
//  Created by miguel tomairo on 1/12/25.
//  Modern iOS 18+ using @Observable macro
//

import Foundation
import Observation

@MainActor
@Observable
final class ForgotPasswordViewModel {

    var email: String = ""
    var isLoading: Bool = false
    var didSendResetLink: Bool = false
    var errorMessage: String?

    private let passwordRecoveryUseCase: PasswordRecoveryUseCase

    init(passwordRecoveryUseCase: PasswordRecoveryUseCase) {
        self.passwordRecoveryUseCase = passwordRecoveryUseCase
    }

    func sendPasswordReset() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                try await passwordRecoveryUseCase.sendPasswordReset(email: email)
                didSendResetLink = true
            } catch {
                errorMessage = "Error al enviar el correo de restablecimiento. Inténtalo de nuevo."
            }
            isLoading = false
        }
    }
}
