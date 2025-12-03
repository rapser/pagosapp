//
//  ResetPasswordViewModel.swift
//  pagosApp
//
//  Created by miguel tomairo on 1/12/25.
//

import Foundation
import Combine

@MainActor
class ResetPasswordViewModel: ObservableObject {

    @Published var newPassword: String = ""
    @Published var confirmPassword: String = ""
    @Published var isLoading: Bool = false
    @Published var didResetPassword: Bool = false
    @Published var errorMessage: String?

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