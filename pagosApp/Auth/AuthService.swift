//
//  AuthService.swift
//  pagosApp
//
//  Protocol abstraction for authentication services (Strategy Pattern)
//  Allows switching between Supabase, Firebase, Auth0, Custom API, etc.
//

import Foundation

/// Authentication result with user data
struct AuthUser: Sendable {
    let id: UUID
    let email: String
    let emailConfirmed: Bool
    let createdAt: Date
    let metadata: [String: Any]?
    
    init(id: UUID, email: String, emailConfirmed: Bool = false, createdAt: Date = Date(), metadata: [String: Any]? = nil) {
        self.id = id
        self.email = email
        self.emailConfirmed = emailConfirmed
        self.createdAt = createdAt
        self.metadata = metadata
    }
}

/// Session information
struct AuthSession: Sendable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date
    let user: AuthUser
    
    var isExpired: Bool {
        Date() >= expiresAt
    }
}

/// Credentials for login
struct LoginCredentials {
    let email: String
    let password: String
}

/// Credentials for registration
struct RegistrationCredentials {
    let email: String
    let password: String
    let metadata: [String: String]?
    
    init(email: String, password: String, metadata: [String: String]? = nil) {
        self.email = email
        self.password = password
        self.metadata = metadata
    }
}

/// Authentication errors
enum AuthError: LocalizedError {
    case invalidCredentials
    case emailAlreadyExists
    case weakPassword
    case invalidEmail
    case userNotFound
    case sessionExpired
    case networkError(Error)
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Email o contraseña incorrectos"
        case .emailAlreadyExists:
            return "El email ya está registrado"
        case .weakPassword:
            return "La contraseña debe tener al menos 6 caracteres"
        case .invalidEmail:
            return "Email inválido"
        case .userNotFound:
            return "Usuario no encontrado"
        case .sessionExpired:
            return "Sesión expirada. Por favor inicia sesión nuevamente"
        case .networkError(let error):
            return "Error de red: \(error.localizedDescription)"
        case .unknown(let message):
            return message
        }
    }
}

/// Generic protocol for authentication services
/// Allows swapping implementations (Supabase, Firebase, Auth0, Custom API)
@MainActor
protocol AuthService {
    /// Sign up a new user
    func signUp(credentials: RegistrationCredentials) async throws -> AuthSession
    
    /// Sign in with email and password
    func signIn(credentials: LoginCredentials) async throws -> AuthSession
    
    /// Sign out current user
    func signOut() async throws
    
    /// Get current session if exists
    func getCurrentSession() async throws -> AuthSession?
    
    /// Refresh expired session
    func refreshSession(refreshToken: String) async throws -> AuthSession
    
    /// Send password reset email
    func sendPasswordResetEmail(email: String) async throws
    
    /// Reset password with token
    func resetPassword(token: String, newPassword: String) async throws
    
    /// Update user email
    func updateEmail(newEmail: String) async throws
    
    /// Update user password
    func updatePassword(newPassword: String) async throws
    
    /// Delete user account
    func deleteAccount() async throws
}

/// Specific protocol for OAuth authentication (optional)
@MainActor
protocol OAuthAuthService: AuthService {
    /// Sign in with Google
    func signInWithGoogle() async throws -> AuthSession
    
    /// Sign in with Apple
    func signInWithApple() async throws -> AuthSession
    
    /// Sign in with Facebook
    func signInWithFacebook() async throws -> AuthSession
}
