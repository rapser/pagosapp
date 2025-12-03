//
//  ForgotPasswordViewModel.swift
//  pagosApp
//
//  Created by miguel tomairo on 1/12/25.
//

import Foundation
import Combine

@MainActor
class ForgotPasswordViewModel: ObservableObject {

    @Published var email: String = ""
    @Published var isLoading: Bool = false
    @Published var didSendResetLink: Bool = false
    @Published var errorMessage: String?

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
