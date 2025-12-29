//
//  PasswordRecoveryUseCase.swift
//  pagosApp
//
//  Created by miguel tomairo on 1/12/25.
//  Modern iOS 18+ using @Observable macro
//

import Foundation
import Observation

@MainActor
@Observable
final class PasswordRecoveryUseCase {
    private let authRepository: AuthRepositoryProtocol

    init(authRepository: AuthRepositoryProtocol) {
        self.authRepository = authRepository
    }

    /// Send password reset email
    func sendPasswordReset(email: String) async -> Result<Void, AuthError> {
        return await authRepository.sendPasswordResetEmail(email: email)
    }

    /// Reset password with token and update password
    func resetPassword(token: String, newPassword: String) async -> Result<Void, AuthError> {
        return await authRepository.resetPassword(token: token, newPassword: newPassword)
    }

    /// Update current user's password
    func updatePassword(newPassword: String) async -> Result<Void, AuthError> {
        return await authRepository.updatePassword(newPassword: newPassword)
    }
}