//
//  SupabasePasswordRecoveryRepository.swift
//  pagosApp
//
//  Created by miguel tomairo on 1/12/25.
//

import Foundation

@MainActor
class SupabasePasswordRecoveryRepository: PasswordRecoveryRepository {
    private let authService: AuthenticationService

    init(authService: AuthenticationService) {
        self.authService = authService
    }

    func sendPasswordReset(email: String) async throws {
        try await authService.sendPasswordReset(email: email)
    }

    func setSession(accessToken: String, refreshToken: String) async throws {
        try await authService.setSession(accessToken: accessToken, refreshToken: refreshToken)
    }

    func updatePassword(newPassword: String) async throws {
        try await authService.updatePassword(newPassword: newPassword)
    }
}