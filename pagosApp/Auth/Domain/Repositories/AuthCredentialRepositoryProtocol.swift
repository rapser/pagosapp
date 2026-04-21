//
//  AuthCredentialRepositoryProtocol.swift
//  pagosApp
//
//  Password and email credential operations (ISP split).
//

import Foundation

@MainActor
protocol AuthCredentialRepositoryProtocol: AnyObject, Sendable {
    func sendPasswordResetEmail(email: String) async -> Result<Void, AuthError>
    func resetPassword(token: String, newPassword: String) async -> Result<Void, AuthError>
    func updatePassword(newPassword: String) async -> Result<Void, AuthError>
    func updateEmail(newEmail: String) async -> Result<Void, AuthError>
}
