//
//  AuthSessionRepositoryProtocol.swift
//  pagosApp
//
//  Session lifecycle and identity (ISP split from AuthRepositoryProtocol).
//

import Foundation

@MainActor
protocol AuthSessionRepositoryProtocol: AnyObject, Sendable {
    func signUp(credentials: RegistrationCredentials) async -> Result<AuthSession, AuthError>
    func signIn(credentials: LoginCredentials) async -> Result<AuthSession, AuthError>
    func signOut() async -> Result<Void, AuthError>
    func getCurrentSession() async -> AuthSession?
    func refreshSession(refreshToken: String) async -> Result<AuthSession, AuthError>
    func getCurrentUserId() async -> UUID?
}
