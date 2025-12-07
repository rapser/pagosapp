//
//  SupabaseAuthAdapter.swift
//  pagosApp
//
//  Concrete implementation of AuthService using Supabase (Adapter Pattern)
//

import Foundation
import Supabase
import OSLog

private let logger = Logger(subsystem: "com.rapser.pagosApp", category: "SupabaseAuthAdapter")

/// Supabase implementation of AuthService
@MainActor
final class SupabaseAuthAdapter: AuthService {
    private let client: SupabaseClient
    
    init(client: SupabaseClient) {
        self.client = client
    }
    
    // MARK: - Sign Up
    
    func signUp(credentials: RegistrationCredentials) async throws -> AuthSession {
        do {
            logger.info("📝 Registrando usuario con email: \(credentials.email)")
            
            // Convert metadata to [String: AnyJSON] for Supabase
            let metadata: [String: AnyJSON] = credentials.metadata?.reduce(into: [:]) { result, pair in
                result[pair.key] = AnyJSON.string(pair.value)
            } ?? [:]
            
            let response = try await client.auth.signUp(
                email: credentials.email,
                password: credentials.password,
                data: metadata
            )
            
            guard let session = response.session else {
                logger.error("❌ No se recibió sesión después del registro")
                throw AuthError.unknown("No se pudo crear la sesión")
            }
            
            logger.info("✅ Usuario registrado exitosamente")
            return mapToAuthSession(session)
            
        } catch let error as AuthError {
            logger.error("❌ Error de autenticación: \(error.localizedDescription)")
            throw error
        } catch {
            logger.error("❌ Error al registrar usuario: \(error.localizedDescription)")
            throw mapSupabaseError(error)
        }
    }
    
    // MARK: - Sign In
    
    func signIn(credentials: LoginCredentials) async throws -> AuthSession {
        do {
            logger.info("🔑 Iniciando sesión con email: \(credentials.email)")
            
            let session = try await client.auth.signIn(
                email: credentials.email,
                password: credentials.password
            )
            
            logger.info("✅ Sesión iniciada exitosamente")
            return mapToAuthSession(session)
            
        } catch {
            logger.error("❌ Error al iniciar sesión: \(error.localizedDescription)")
            throw mapSupabaseError(error)
        }
    }
    
    // MARK: - Sign Out
    
    func signOut() async throws {
        do {
            logger.info("🚪 Cerrando sesión")
            try await client.auth.signOut()
            logger.info("✅ Sesión cerrada exitosamente")
            
        } catch {
            logger.error("❌ Error al cerrar sesión: \(error.localizedDescription)")
            throw AuthError.networkError(error)
        }
    }
    
    // MARK: - Get Current Session
    
    func getCurrentSession() async throws -> AuthSession? {
        do {
            logger.debug("🔍 Obteniendo sesión actual")
            let session = try await client.auth.session
            logger.debug("✅ Sesión encontrada")
            return mapToAuthSession(session)
            
        } catch {
            logger.debug("⚠️ No hay sesión activa")
            return nil
        }
    }
    
    // MARK: - Refresh Session
    
    func refreshSession(refreshToken: String) async throws -> AuthSession {
        do {
            logger.info("🔄 Renovando sesión")
            
            let session = try await client.auth.refreshSession(refreshToken: refreshToken)
            
            logger.info("✅ Sesión renovada exitosamente")
            return mapToAuthSession(session)
            
        } catch {
            logger.error("❌ Error al renovar sesión: \(error.localizedDescription)")
            throw AuthError.sessionExpired
        }
    }
    
    // MARK: - Password Reset
    
    func sendPasswordResetEmail(email: String) async throws {
        do {
            logger.info("📧 Enviando email de recuperación a: \(email)")
            
            try await client.auth.resetPasswordForEmail(email)
            
            logger.info("✅ Email de recuperación enviado")
            
        } catch {
            logger.error("❌ Error al enviar email de recuperación: \(error.localizedDescription)")
            throw AuthError.networkError(error)
        }
    }
    
    func resetPassword(token: String, newPassword: String) async throws {
        do {
            logger.info("🔑 Actualizando contraseña")
            
            let user = try await client.auth.update(user: UserAttributes(password: newPassword))
            
            logger.info("✅ Contraseña actualizada exitosamente")
            
        } catch {
            logger.error("❌ Error al actualizar contraseña: \(error.localizedDescription)")
            throw mapSupabaseError(error)
        }
    }
    
    // MARK: - Update User
    
    func updateEmail(newEmail: String) async throws {
        do {
            logger.info("📧 Actualizando email a: \(newEmail)")
            
            let user = try await client.auth.update(user: UserAttributes(email: newEmail))
            
            logger.info("✅ Email actualizado exitosamente")
            
        } catch {
            logger.error("❌ Error al actualizar email: \(error.localizedDescription)")
            throw mapSupabaseError(error)
        }
    }
    
    func updatePassword(newPassword: String) async throws {
        do {
            logger.info("🔑 Actualizando contraseña")
            
            let user = try await client.auth.update(user: UserAttributes(password: newPassword))
            
            logger.info("✅ Contraseña actualizada exitosamente")
            
        } catch {
            logger.error("❌ Error al actualizar contraseña: \(error.localizedDescription)")
            throw mapSupabaseError(error)
        }
    }
    
    // MARK: - Delete Account
    
    func deleteAccount() async throws {
        do {
            logger.warning("🗑️ Eliminando cuenta de usuario")
            
            // Supabase doesn't have a direct delete user endpoint
            // This typically needs to be done via an admin endpoint or database trigger
            // For now, we'll just sign out
            try await signOut()
            
            logger.warning("⚠️ Cuenta desactivada localmente. Contacta al administrador para eliminación completa.")
            
        } catch {
            logger.error("❌ Error al eliminar cuenta: \(error.localizedDescription)")
            throw AuthError.networkError(error)
        }
    }
    
    // MARK: - Private Helpers
    
    private func mapToAuthSession(_ session: Session) -> AuthSession {
        let user = AuthUser(
            id: session.user.id,
            email: session.user.email ?? "",
            emailConfirmed: session.user.emailConfirmedAt != nil,
            createdAt: session.user.createdAt,
            metadata: session.user.userMetadata
        )
        
        return AuthSession(
            accessToken: session.accessToken,
            refreshToken: session.refreshToken,
            expiresAt: Date(timeIntervalSince1970: TimeInterval(session.expiresAt ?? 0)),
            user: user
        )
    }
    
    private func mapSupabaseError(_ error: Error) -> AuthError {
        let errorMessage = error.localizedDescription.lowercased()
        
        if errorMessage.contains("invalid login credentials") || errorMessage.contains("invalid email or password") {
            return .invalidCredentials
        } else if errorMessage.contains("user already registered") || errorMessage.contains("email already exists") {
            return .emailAlreadyExists
        } else if errorMessage.contains("password") && errorMessage.contains("short") {
            return .weakPassword
        } else if errorMessage.contains("invalid email") {
            return .invalidEmail
        } else if errorMessage.contains("user not found") {
            return .userNotFound
        } else if errorMessage.contains("expired") || errorMessage.contains("token") {
            return .sessionExpired
        } else {
            return .networkError(error)
        }
    }
}
