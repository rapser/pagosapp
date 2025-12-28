//
//  PasswordRecoveryRepository.swift
//  pagosApp
//
//  Created by miguel tomairo on 1/12/25.
//

import Foundation

protocol PasswordRecoveryRepository {
    func sendPasswordReset(email: String) async throws
    func setSession(accessToken: String, refreshToken: String) async throws
    func updatePassword(newPassword: String) async throws
}