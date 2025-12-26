//
//  AuthRepository.swift
//  pagosApp
//
//  Repository that manages authentication through abstract AuthService (Repository Pattern)
//  Business logic layer between ViewModels and AuthService implementations
//  Modern iOS 18+ using @Observable macro
//

import Foundation
import Observation
import OSLog
import Supabase

private let logger = Logger(subsystem: "com.rapser.pagosApp", category: "AuthRepository")

/// Repository for authentication operations
/// Coordinates between UI and AuthService adapter
@MainActor
@Observable
final class AuthRepository {
    // MARK: - Observable Properties
    
    private(set) var currentUser: AuthUser?
    private(set) var isAuthenticated: Bool = false
    private(set) var isLoading: Bool = false
    
    // MARK: - Private Properties

    private let authService: any AuthService

    // MARK: - Internal Properties (for AuthenticationManager)

    /// Expose authService for specific use cases (e.g., checking connection status)
    internal var authServiceInternal: any AuthService {
        return authService
    }
    
    // MARK: - Public Properties
    
    /// Exposes the underlying Supabase client for legacy compatibility
    /// Use only when absolutely necessary (e.g., UserProfileService)
    var supabaseClient: SupabaseClient? {
        return (authService as? SupabaseAuthAdapter)?.supabaseClient
    }
    
    // MARK: - Initialization
    
    init(authService: any AuthService) {
        self.authService = authService
        
        logger.info("🔧 AuthRepository inicializado")
        
        // Check for existing session on init
        Task {
            await checkExistingSession()
        }
    }
    
    // MARK: - Authentication Methods
    
    /// Register a new user
    func register(email: String, password: String, metadata: [String: String]? = nil) async throws {
        logger.info("📝 Registrando usuario: \(email)")
        isLoading = true
        defer { isLoading = false }
        
        // Validate inputs
        try validateEmail(email)
        try validatePassword(password)
        
        let credentials = RegistrationCredentials(
            email: email,
            password: password,
            metadata: metadata
        )
        
        do {
            let session = try await authService.signUp(credentials: credentials)
            try saveSession(session)
            updateAuthenticationState(with: session.user)
            logger.info("✅ Usuario registrado exitosamente")
        } catch {
            logger.error("❌ Error al registrar: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Login with email and password
    func login(email: String, password: String) async throws {
        logger.info("🔑 Iniciando sesión: \(email)")
        isLoading = true
        defer { isLoading = false }
        
        // Validate inputs
        try validateEmail(email)
        
        let credentials = LoginCredentials(email: email, password: password)
        
        do {
            let session = try await authService.signIn(credentials: credentials)
            try saveSession(session)
            updateAuthenticationState(with: session.user)
            logger.info("✅ Sesión iniciada exitosamente")
        } catch {
            logger.error("❌ Error al iniciar sesión: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Logout current user
    func logout() async throws {
        logger.info("🚪 Cerrando sesión")
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await authService.signOut()
            clearSession()
            clearAuthenticationState()
            logger.info("✅ Sesión cerrada exitosamente")
        } catch {
            logger.error("❌ Error al cerrar sesión: \(error.localizedDescription)")
            // Clear local state even if remote logout fails
            clearSession()
            clearAuthenticationState()
            throw error
        }
    }
    
    /// Send password reset email
    func sendPasswordReset(email: String) async throws {
        logger.info("📧 Enviando email de recuperación a: \(email)")
        isLoading = true
        defer { isLoading = false }
        
        try validateEmail(email)
        
        do {
            try await authService.sendPasswordResetEmail(email: email)
            logger.info("✅ Email de recuperación enviado")
        } catch {
            logger.error("❌ Error al enviar email: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Reset password with token
    func resetPassword(token: String, newPassword: String) async throws {
        logger.info("🔑 Restableciendo contraseña")
        isLoading = true
        defer { isLoading = false }
        
        try validatePassword(newPassword)
        
        do {
            try await authService.resetPassword(token: token, newPassword: newPassword)
            logger.info("✅ Contraseña restablecida exitosamente")
        } catch {
            logger.error("❌ Error al restablecer contraseña: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Update user email
    func updateEmail(newEmail: String) async throws {
        logger.info("📧 Actualizando email a: \(newEmail)")
        isLoading = true
        defer { isLoading = false }
        
        try validateEmail(newEmail)
        
        do {
            try await authService.updateEmail(newEmail: newEmail)
            // Refresh session to get updated user
            try await refreshSession()
            logger.info("✅ Email actualizado exitosamente")
        } catch {
            logger.error("❌ Error al actualizar email: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Update user password
    func updatePassword(newPassword: String) async throws {
        logger.info("🔑 Actualizando contraseña")
        isLoading = true
        defer { isLoading = false }
        
        try validatePassword(newPassword)
        
        do {
            try await authService.updatePassword(newPassword: newPassword)
            logger.info("✅ Contraseña actualizada exitosamente")
        } catch {
            logger.error("❌ Error al actualizar contraseña: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Delete user account
    func deleteAccount() async throws {
        logger.warning("🗑️ Eliminando cuenta")
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await authService.deleteAccount()
            clearSession()
            clearAuthenticationState()
            logger.info("✅ Cuenta eliminada exitosamente")
        } catch {
            logger.error("❌ Error al eliminar cuenta: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Session Management
    
    /// Check if there's an existing valid session
    private func checkExistingSession() async {
        logger.debug("🔍 Verificando sesión existente")

        do {
            if let session = try await authService.getCurrentSession() {
                if session.isExpired {
                    logger.debug("⚠️ Sesión expirada, intentando renovar")
                    try await refreshSession()
                } else {
                    logger.debug("✅ Sesión válida encontrada")
                    updateAuthenticationState(with: session.user)
                }
            } else {
                logger.debug("ℹ️ No hay sesión activa, intentando restaurar desde Keychain")
                // Intentar restaurar sesión con tokens guardados si existen
                if let accessToken = KeychainManager.getAccessToken(),
                   let refreshToken = KeychainManager.getRefreshToken() {
                    do {
                        let session = try await authService.setSession(accessToken: accessToken, refreshToken: refreshToken)
                        if session.isExpired {
                            logger.debug("⚠️ Sesión restaurada pero expirada, intentando refresh")
                            try await refreshSession()
                        } else {
                            logger.debug("✅ Sesión restaurada exitosamente")
                            updateAuthenticationState(with: session.user)
                        }
                    } catch {
                        logger.debug("❌ No se pudo restaurar sesión: \(error.localizedDescription)")
                        clearAuthenticationState()
                    }
                } else {
                    logger.debug("ℹ️ No hay tokens guardados")
                    clearAuthenticationState()
                }
            }
        } catch {
            logger.error("❌ Error al verificar sesión: \(error.localizedDescription)")
            clearAuthenticationState()
        }
    }
    
    /// Refresh expired session
    func refreshSession() async throws {
        logger.info("🔄 Renovando sesión")

        guard let refreshToken = KeychainManager.getRefreshToken() else {
            logger.error("❌ No hay refresh token disponible")
            throw AuthError.sessionExpired
        }

        do {
            let session = try await authService.refreshSession(refreshToken: refreshToken)
            try saveSession(session)
            updateAuthenticationState(with: session.user)
            logger.info("✅ Sesión renovada exitosamente")
        } catch {
            logger.error("❌ Error al renovar sesión: \(error.localizedDescription)")
            clearSession()
            clearAuthenticationState()
            throw AuthError.sessionExpired
        }
    }

    /// Ensure the current session is valid, refreshing if necessary
    /// Call this before performing critical operations (sync, API calls, etc.)
    /// IMPORTANT: This does NOT clear local authentication state - app can work offline
    /// Only throws an error to indicate sync cannot proceed, but user stays "logged in" locally
    func ensureValidSession() async throws {
        logger.debug("🔍 Verificando validez de sesión antes de operación crítica")

        // Check if we have a current session
        guard let session = try await authService.getCurrentSession() else {
            logger.warning("⚠️ No hay sesión activa en Supabase - puede ser modo offline")
            // Don't clear local state - user can work offline
            throw AuthError.sessionExpired
        }

        // If session is expired, try to refresh without clearing local state
        if session.isExpired {
            logger.info("⚠️ Sesión expirada, renovando automáticamente...")

            guard let refreshToken = KeychainManager.getRefreshToken() else {
                logger.warning("⚠️ No hay refresh token disponible - modo offline")
                throw AuthError.sessionExpired
            }

            // Try to refresh - may fail if offline
            // IMPORTANT: Don't clear local state if it fails
            do {
                let newSession = try await authService.refreshSession(refreshToken: refreshToken)
                try saveSession(newSession)
                updateAuthenticationState(with: newSession.user)
                logger.info("✅ Sesión renovada exitosamente")
            } catch {
                logger.warning("⚠️ No se pudo renovar sesión - probablemente sin conexión")
                logger.info("💡 Usuario puede seguir trabajando localmente")
                // Don't clear local state - just throw to indicate sync can't proceed
                throw AuthError.sessionExpired
            }
        } else {
            logger.debug("✅ Sesión válida y activa")
        }
    }
    
    // MARK: - Private Helpers
    
    private func saveSession(_ session: AuthSession) throws {
        try KeychainManager.saveAccessToken(session.accessToken)
        try KeychainManager.saveRefreshToken(session.refreshToken)
        try KeychainManager.saveUserId(session.user.id.uuidString)
        logger.debug("💾 Sesión guardada en Keychain")
    }
    
    private func clearSession() {
        KeychainManager.clearAllTokens()
        logger.debug("🗑️ Sesión eliminada del Keychain")
    }
    
    private func updateAuthenticationState(with user: AuthUser) {
        self.currentUser = user
        self.isAuthenticated = true
        logger.debug("✅ Estado de autenticación actualizado")
    }
    
    private func clearAuthenticationState() {
        self.currentUser = nil
        self.isAuthenticated = false
        logger.debug("🗑️ Estado de autenticación limpio")
    }
    
    // MARK: - Validation
    
    private func validateEmail(_ email: String) throws {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        guard emailPredicate.evaluate(with: email) else {
            throw AuthError.invalidEmail
        }
    }
    
    private func validatePassword(_ password: String) throws {
        guard password.count >= 6 else {
            throw AuthError.weakPassword
        }
    }
}
