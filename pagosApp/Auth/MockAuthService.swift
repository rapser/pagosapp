//
//  MockAuthService.swift
//  pagosApp
//
//  Created by miguel tomairo on 26/12/25.
//


import Foundation
import OSLog

private let logger = Logger(subsystem: "com.rapser.pagosApp", category: "AuthRepository")

/// Mock implementation for testing or when no provider is configured
@MainActor
final class MockAuthService: AuthService {
    func setSession(accessToken: String, refreshToken: String) async throws -> AuthSession {
        logger.warning("⚠️ MockAuthService.setSession llamado")
        throw AuthError.unknown("Mock service - no real authentication")
    }
    
    func signUp(credentials: RegistrationCredentials) async throws -> AuthSession {
        logger.warning("⚠️ MockAuthService.signUp llamado")
        throw AuthError.unknown("Mock service - no real authentication")
    }
    
    func signIn(credentials: LoginCredentials) async throws -> AuthSession {
        logger.warning("⚠️ MockAuthService.signIn llamado")
        throw AuthError.unknown("Mock service - no real authentication")
    }
    
    func signOut() async throws {
        logger.warning("⚠️ MockAuthService.signOut llamado")
    }
    
    func getCurrentSession() async throws -> AuthSession? {
        logger.warning("⚠️ MockAuthService.getCurrentSession llamado")
        return nil
    }
    
    func refreshSession(refreshToken: String) async throws -> AuthSession {
        logger.warning("⚠️ MockAuthService.refreshSession llamado")
        throw AuthError.sessionExpired
    }
    
    func sendPasswordResetEmail(email: String) async throws {
        logger.warning("⚠️ MockAuthService.sendPasswordResetEmail llamado")
    }
    
    func resetPassword(token: String, newPassword: String) async throws {
        logger.warning("⚠️ MockAuthService.resetPassword llamado")
    }
    
    func updateEmail(newEmail: String) async throws {
        logger.warning("⚠️ MockAuthService.updateEmail llamado")
    }
    
    func updatePassword(newPassword: String) async throws {
        logger.warning("⚠️ MockAuthService.updatePassword llamado")
    }
    
    func deleteAccount() async throws {
        logger.warning("⚠️ MockAuthService.deleteAccount llamado")
    }
}
