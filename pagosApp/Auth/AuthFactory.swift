//
//  AuthFactory.swift
//  pagosApp
//
//  Factory for creating authentication components with different providers (Factory Pattern)
//  Centralizes configuration and dependency injection for auth module
//

import Foundation
import Supabase
import OSLog

private let logger = Logger(subsystem: "com.rapser.pagosApp", category: "AuthFactory")

/// Authentication provider types
enum AuthProvider {
    case supabase
    case firebase
    case auth0
    case customAPI
}

/// Configuration for authentication
struct AuthConfiguration {
    let provider: AuthProvider
    let supabaseURL: URL?
    let supabaseKey: String?
    let firebaseConfig: [String: Any]?
    let customAPIBaseURL: URL?
    
    /// Default configuration using Supabase
    static func supabase(url: URL, key: String) -> AuthConfiguration {
        return AuthConfiguration(
            provider: .supabase,
            supabaseURL: url,
            supabaseKey: key,
            firebaseConfig: nil,
            customAPIBaseURL: nil
        )
    }
    
    /// Firebase configuration (for future implementation)
    static func firebase(config: [String: Any]) -> AuthConfiguration {
        return AuthConfiguration(
            provider: .firebase,
            supabaseURL: nil,
            supabaseKey: nil,
            firebaseConfig: config,
            customAPIBaseURL: nil
        )
    }
    
    /// Custom API configuration (for future implementation)
    static func customAPI(baseURL: URL) -> AuthConfiguration {
        return AuthConfiguration(
            provider: .customAPI,
            supabaseURL: nil,
            supabaseKey: nil,
            firebaseConfig: nil,
            customAPIBaseURL: baseURL
        )
    }
}

/// Factory for creating authentication components
@MainActor
final class AuthFactory {
    static let shared = AuthFactory()
    
    private var configuration: AuthConfiguration?
    private var authService: (any AuthService)?
    private var authRepository: AuthRepository?
    
    private init() {}
    
    // MARK: - Configuration
    
    /// Configure the factory with authentication provider
    func configure(_ configuration: AuthConfiguration) {
        logger.info("🔧 Configurando AuthFactory con provider: \(String(describing: configuration.provider))")
        self.configuration = configuration
        
        // Reset existing instances to force recreation with new config
        self.authService = nil
        self.authRepository = nil
    }
    
    // MARK: - Factory Methods
    
    /// Create or get existing AuthService implementation
    func makeAuthService() -> any AuthService {
        if let existing = authService {
            return existing
        }
        
        guard let config = configuration else {
            logger.error("❌ AuthFactory no está configurado. Usando mock service.")
            let mock = MockAuthService()
            self.authService = mock
            return mock
        }
        
        let service: any AuthService
        
        switch config.provider {
        case .supabase:
            service = makeSupabaseAuthService(config: config)
            
        case .firebase:
            logger.warning("⚠️ Firebase auth no implementado aún. Usando mock.")
            service = MockAuthService()
            
        case .auth0:
            logger.warning("⚠️ Auth0 no implementado aún. Usando mock.")
            service = MockAuthService()
            
        case .customAPI:
            logger.warning("⚠️ Custom API no implementado aún. Usando mock.")
            service = MockAuthService()
        }
        
        self.authService = service
        return service
    }
    
    /// Create or get existing AuthRepository
    func makeAuthRepository() -> AuthRepository {
        if let existing = authRepository {
            return existing
        }
        
        let service = makeAuthService()
        let repository = AuthRepository(authService: service)
        
        self.authRepository = repository
        logger.info("✅ AuthRepository creado")
        
        return repository
    }
    
    // MARK: - Private Factory Methods
    
    private func makeSupabaseAuthService(config: AuthConfiguration) -> any AuthService {
        guard let url = config.supabaseURL,
              let key = config.supabaseKey else {
            logger.error("❌ Configuración de Supabase incompleta")
            return MockAuthService()
        }
        
        let client = SupabaseClient(supabaseURL: url, supabaseKey: key)
        let adapter = SupabaseAuthAdapter(client: client)
        
        logger.info("✅ SupabaseAuthAdapter creado")
        return adapter
    }
}

// MARK: - Mock Implementation

/// Mock implementation for testing or when no provider is configured
@MainActor
final class MockAuthService: AuthService {
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
