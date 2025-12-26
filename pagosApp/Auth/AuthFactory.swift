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
