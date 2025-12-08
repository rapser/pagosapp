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
    private let repository: PasswordRecoveryRepository

    init(repository: PasswordRecoveryRepository) {
        self.repository = repository
    }

    func sendPasswordReset(email: String) async throws {
        try await repository.sendPasswordReset(email: email)
    }

    func resetPassword(accessToken: String, refreshToken: String, newPassword: String) async throws {
        try await repository.setSession(accessToken: accessToken, refreshToken: refreshToken)
        try await repository.updatePassword(newPassword: newPassword)
    }
}