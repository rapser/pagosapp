//
//  FirebaseAuthAdapter.swift
//  pagosApp
//
//  Firebase implementation of AuthService (Example - not fully implemented)
//  Uncomment and implement when Firebase is added to the project
//

import Foundation
import OSLog

private let logger = Logger(subsystem: "com.rapser.pagosApp", category: "FirebaseAuthAdapter")

@MainActor
final class FirebaseAuthAdapter: AuthService {
    init() {
        logger.warning("⚠️ FirebaseAuthAdapter no está completamente implementado")
        logger.info("ℹ️ Para implementar Firebase:")
        logger.info("1. Agrega Firebase SDK al proyecto")
        logger.info("2. Descomenta el código en FirebaseAuthAdapter.swift")
        logger.info("3. Actualiza AuthFactory.swift")
    }
    
    func signUp(credentials: RegistrationCredentials) async throws -> AuthSession {
        throw AuthError.unknown("Firebase no está configurado. Ver FirebaseAuthAdapter.swift")
    }
    
    func signIn(credentials: LoginCredentials) async throws -> AuthSession {
        throw AuthError.unknown("Firebase no está configurado. Ver FirebaseAuthAdapter.swift")
    }
    
    func signOut() async throws {
        throw AuthError.unknown("Firebase no está configurado. Ver FirebaseAuthAdapter.swift")
    }
    
    func getCurrentSession() async throws -> AuthSession? {
        return nil
    }
    
    func refreshSession(refreshToken: String) async throws -> AuthSession {
        throw AuthError.sessionExpired
    }

    func setSession(accessToken: String, refreshToken: String) async throws -> AuthSession {
        throw AuthError.unknown("Firebase no está configurado. Ver FirebaseAuthAdapter.swift")
    }

    func sendPasswordResetEmail(email: String) async throws {
        throw AuthError.unknown("Firebase no está configurado. Ver FirebaseAuthAdapter.swift")
    }
    
    func resetPassword(token: String, newPassword: String) async throws {
        throw AuthError.unknown("Firebase no está configurado. Ver FirebaseAuthAdapter.swift")
    }
    
    func updateEmail(newEmail: String) async throws {
        throw AuthError.unknown("Firebase no está configurado. Ver FirebaseAuthAdapter.swift")
    }
    
    func updatePassword(newPassword: String) async throws {
        throw AuthError.unknown("Firebase no está configurado. Ver FirebaseAuthAdapter.swift")
    }
    
    func deleteAccount() async throws {
        throw AuthError.unknown("Firebase no está configurado. Ver FirebaseAuthAdapter.swift")
    }
}
