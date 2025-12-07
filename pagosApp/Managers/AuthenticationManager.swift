import Foundation
@preconcurrency import LocalAuthentication
import Combine
import OSLog
import SwiftData
import Supabase

/// DEPRECATED: Este manager mantiene compatibilidad con código antiguo
/// USO RECOMENDADO: Utiliza AuthRepository directamente en ViewModels
/// Para nuevas implementaciones, usa: AuthFactory.shared.makeAuthRepository()
@MainActor
class AuthenticationManager: ObservableObject {
    // DEPRECATED: Usa AuthRepository en su lugar
    public let authService: AuthenticationService
    
    // NEW: Modern auth repository with provider abstraction
    private let authRepository: AuthRepository
    
    private var cancellables = Set<AnyCancellable>()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "Authentication")
    private let errorHandler = ErrorHandler.shared

    private let lastActiveTimestampKey = "lastActiveTimestamp"
    private let sessionTimeoutInSeconds: TimeInterval = 604800 // 1 semana (7 días * 24 horas * 60 minutos * 60 segundos)
    
    @Published var isAuthenticated = false
    @Published var canUseBiometrics = false
    @Published var showInactivityAlert = false
    @Published var hasLoggedInWithCredentials = false
    @Published var isLoading: Bool = false
    
    // DEPRECATED initializer - mantiene compatibilidad
    init(authService: AuthenticationService) {
        self.authService = authService
        
        // Initialize new auth repository
        self.authRepository = AuthFactory.shared.makeAuthRepository()
        
        self.hasLoggedInWithCredentials = KeychainManager.getHasLoggedIn()

        checkBiometricAvailability()

        // Check if there's a Supabase session available
        let hasSupabaseSession = (authService.isAuthenticated)

        // Check if Face ID is enabled
        let isFaceIDEnabled = SettingsManager.shared.isBiometricLockEnabled && canUseBiometrics

        // Determine initial authentication state
        if isFaceIDEnabled {
            // If Face ID is enabled, ALWAYS require Face ID login for security
            self.isAuthenticated = false
        } else {
            // If Face ID is NOT enabled, use Supabase session state
            self.isAuthenticated = hasSupabaseSession
        }

        // Observe changes from the injected AuthenticationService (legacy)
        authService.isAuthenticatedPublisher
            .sink { [weak self] isAuthenticated in
                guard let self = self else { return }

                // Only auto-update if Face ID is NOT enabled
                let isFaceIDEnabled = SettingsManager.shared.isBiometricLockEnabled && self.canUseBiometrics
                if !isFaceIDEnabled {
                    self.isAuthenticated = isAuthenticated
                }
            }
            .store(in: &cancellables)
        
        // Observe changes from the new AuthRepository
        authRepository.$isAuthenticated
            .sink { [weak self] isAuthenticated in
                guard let self = self else { return }
                
                let isFaceIDEnabled = SettingsManager.shared.isBiometricLockEnabled && self.canUseBiometrics
                if !isFaceIDEnabled {
                    self.isAuthenticated = isAuthenticated
                }
            }
            .store(in: &cancellables)
    }
    
    /// NEW: Recommended initializer using AuthRepository directly
    init(authRepository: AuthRepository) {
        // For backward compatibility, we still need authService
        // Create Supabase client for legacy compatibility
        let supabaseClient: SupabaseClient
        do {
            supabaseClient = SupabaseClient(
                supabaseURL: try ConfigurationManager.supabaseURL,
                supabaseKey: try ConfigurationManager.supabaseKey
            )
        } catch {
            // Fallback: create a dummy client if configuration fails
            fatalError("Failed to load Supabase configuration: \(error)")
        }
        
        self.authService = SupabaseAuthService(client: supabaseClient)
        self.authRepository = authRepository
        
        self.hasLoggedInWithCredentials = KeychainManager.getHasLoggedIn()
        checkBiometricAvailability()
        
        let isFaceIDEnabled = SettingsManager.shared.isBiometricLockEnabled && canUseBiometrics
        
        if isFaceIDEnabled {
            self.isAuthenticated = false
        } else {
            self.isAuthenticated = authRepository.isAuthenticated
        }
        
        // Observe changes from AuthRepository
        authRepository.$isAuthenticated
            .sink { [weak self] isAuthenticated in
                guard let self = self else { return }
                
                let isFaceIDEnabled = SettingsManager.shared.isBiometricLockEnabled && self.canUseBiometrics
                if !isFaceIDEnabled {
                    self.isAuthenticated = isAuthenticated
                }
            }
            .store(in: &cancellables)
    }
    
    private func checkBiometricAvailability() {
        let context = LAContext()
        var error: NSError?
        
        // Check if biometrics can be evaluated
        let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        
        #if targetEnvironment(simulator)
        // In simulator, always allow Face ID for testing
        canUseBiometrics = true
        logger.info("🧪 Simulator detected: Face ID enabled for testing")
        #else
        // On real device, use actual biometric availability
        canUseBiometrics = canEvaluate
        if let error = error {
            logger.warning("Biometrics not available: \(error.localizedDescription)")
        }
        #endif
    }

    @MainActor
    func login(email: String, password: String) async -> AuthenticationError? {
        isLoading = true
        defer { isLoading = false }

        do {
            logger.info("Attempting login for \(email)")
            
            // Use new AuthRepository (handles validation internally)
            try await authRepository.login(email: email, password: password)
            
            self.hasLoggedInWithCredentials = true
            _ = KeychainManager.setHasLoggedIn(true)

            // Always save credentials to Keychain on successful login
            let saved = KeychainManager.saveCredentials(email: email, password: password)
            if saved {
                logger.info("✅ Credentials saved to Keychain")
            } else {
                logger.warning("⚠️ Failed to save credentials to Keychain")
            }

            // Manually set isAuthenticated to true after successful login
            self.isAuthenticated = true

            logger.info("✅ Login successful for \(email)")
            return nil
        } catch let authError as AuthError {
            logger.error("❌ Login failed: \(authError.localizedDescription)")
            // Map new AuthError to legacy AuthenticationError
            let legacyError = mapToLegacyError(authError)
            errorHandler.handle(legacyError)
            return legacyError
        } catch let authError as AuthenticationError {
            logger.error("❌ Login failed: \(authError.localizedDescription)")
            errorHandler.handle(authError)
            return authError
        } catch {
            logger.error("❌ Login failed with unknown error: \(error.localizedDescription)")
            let authError = AuthenticationError.unknown(error)
            errorHandler.handle(authError)
            return authError
        }
    }
    
    @MainActor
    func register(email: String, password: String) async -> AuthenticationError? {
        isLoading = true
        defer { isLoading = false }

        do {
            logger.info("Attempting registration for \(email)")
            
            // Use new AuthRepository (handles validation internally)
            try await authRepository.register(email: email, password: password)
            
            self.hasLoggedInWithCredentials = true
            _ = KeychainManager.setHasLoggedIn(true)

            // Manually set isAuthenticated to true after successful registration
            self.isAuthenticated = true

            logger.info("✅ Registration successful for \(email)")
            return nil
        } catch let authError as AuthError {
            logger.error("❌ Registration failed: \(authError.localizedDescription)")
            let legacyError = mapToLegacyError(authError)
            errorHandler.handle(legacyError)
            return legacyError
        } catch let authError as AuthenticationError {
            logger.error("❌ Registration failed: \(authError.localizedDescription)")
            errorHandler.handle(authError)
            return authError
        } catch {
            logger.error("❌ Registration failed with unknown error: \(error.localizedDescription)")
            let authError = AuthenticationError.unknown(error)
            errorHandler.handle(authError)
            return authError
        }
    }
    
    @MainActor
    func sendPasswordReset(email: String) async -> AuthenticationError? {
        isLoading = true
        defer { isLoading = false }
        
        do {
            logger.info("Attempting to send password reset for \(email)")
            
            // Use new AuthRepository (handles validation internally)
            try await authRepository.sendPasswordReset(email: email)
            
            logger.info("✅ Password reset email sent successfully for \(email)")
            return nil
        } catch let authError as AuthError {
            logger.error("❌ Password reset failed: \(authError.localizedDescription)")
            let legacyError = mapToLegacyError(authError)
            errorHandler.handle(legacyError)
            return legacyError
        } catch let authError as AuthenticationError {
            logger.error("❌ Password reset failed: \(authError.localizedDescription)")
            errorHandler.handle(authError)
            return authError
        } catch {
            logger.error("❌ Password reset failed with unknown error: \(error.localizedDescription)")
            let authError = AuthenticationError.unknown(error)
            errorHandler.handle(authError)
            return authError
        }
    }
    
    @MainActor
    func authenticateWithBiometrics() async {
        guard canUseBiometrics else { return }
        
        // Check if credentials are stored
        guard KeychainManager.hasStoredCredentials() else {
            logger.warning("⚠️ No credentials stored in Keychain for Face ID")
            return
        }

        let context = LAContext()
        let reason = "Inicia sesión con Face ID para acceder a tus pagos."

        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] success, authenticationError in
            Task { @MainActor in
                guard let self = self else { return }
                
                if success {
                    // Face ID successful, now start loading and perform login
                    self.isLoading = true
                    
                    // Retrieve credentials from Keychain using the same context (avoids second Face ID prompt)
                    guard let credentials = KeychainManager.retrieveCredentials(context: context) else {
                        self.logger.error("❌ Failed to retrieve credentials from Keychain")
                        self.isLoading = false
                        return
                    }
                    
                    // Perform login with retrieved credentials
                    self.logger.info("🔐 Face ID successful, logging in with stored credentials")
                    let error = await self.login(email: credentials.email, password: credentials.password)
                    
                    if error == nil {
                        self.logger.info("✅ Face ID login successful")
                    } else {
                        self.logger.error("❌ Face ID login failed: \(error?.localizedDescription ?? "unknown")")
                    }
                    
                    self.isLoading = false
                } else {
                    self.logger.warning("⚠️ Face ID authentication failed")
                    if let error = authenticationError {
                        self.logger.error("Face ID error: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    @MainActor
    func logout(inactivity: Bool = false, modelContext: ModelContext? = nil) async {
        isLoading = true
        defer { isLoading = false }

        // Always sign out using new AuthRepository
        do {
            try await authRepository.logout()
            logger.info("✅ Session closed on logout")
        } catch let authError as AuthError {
            logger.error("Logout failed with auth error: \(authError.localizedDescription)")
        } catch let authError as AuthenticationError {
            logger.error("Logout failed with auth error: \(authError.localizedDescription)")
        } catch {
            logger.error("Unknown logout error: \(error.localizedDescription)")
        }

        // Always clear local database on logout
        // This ONLY clears SwiftData locally, NEVER touches remote storage
        PaymentSyncManager.shared.clearLocalDatabase(modelContext: modelContext)
        logger.info("Local SwiftData database cleared on logout (remote storage untouched)")

        // If Face ID is NOT enabled, delete credentials from Keychain
        if !SettingsManager.shared.isBiometricLockEnabled {
            _ = KeychainManager.deleteCredentials()
            logger.info("🗑️ Credentials deleted from Keychain (Face ID disabled)")
        } else {
            logger.info("🔐 Credentials kept in Keychain (Face ID enabled)")
        }

        // Clear timestamp
        UserDefaults.standard.removeObject(forKey: self.lastActiveTimestampKey)

        // Manually set isAuthenticated to false to show login screen
        self.isAuthenticated = false

        if inactivity {
            self.showInactivityAlert = true
        }
    }
    
    func checkSession() {
        #if DEBUG
        return
        #else
        if let lastActiveTimestamp = UserDefaults.standard.object(forKey: lastActiveTimestampKey) as? Date {
            let elapsedTime = Date().timeIntervalSince(lastActiveTimestamp)
            if elapsedTime > sessionTimeoutInSeconds {
                Task {
                    // Clear hasLoggedInWithCredentials since session is too old
                    // This will require user to login with email/password again
                    // BUT we DON'T touch isBiometricLockEnabled (the switch stays ON)
                    self.hasLoggedInWithCredentials = false
                    KeychainManager.deleteHasLoggedIn()

                    // Full logout - always close Supabase session
                    await logout(inactivity: true)
                }
            }
        } else {
            startInactivityTimer()
        }
        #endif
    }
    
    func startInactivityTimer() {
        updateLastActiveTimestamp()
    }

    func updateLastActiveTimestamp() {
        UserDefaults.standard.set(Date(), forKey: lastActiveTimestampKey)
    }

    /// Clears the biometric login capability for this device
    /// This should be called when the user explicitly disables Face ID in settings
    func clearBiometricCredentials(modelContext: ModelContext? = nil) async {
        self.hasLoggedInWithCredentials = false
        KeychainManager.deleteHasLoggedIn()
        
        // Delete stored credentials from Keychain when Face ID is disabled
        _ = KeychainManager.deleteCredentials()
        logger.info("🔐 Credentials removed from Keychain (Face ID disabled)")
    }
    
    // MARK: - Error Mapping
    
    /// Maps new AuthError to legacy AuthenticationError for backward compatibility
    private func mapToLegacyError(_ authError: AuthError) -> AuthenticationError {
        switch authError {
        case .invalidCredentials:
            return .wrongCredentials
        case .emailAlreadyExists:
            return .wrongCredentials // Legacy: treat as wrong credentials
        case .weakPassword:
            return .invalidEmailFormat // Legacy: closest match available
        case .invalidEmail:
            return .invalidEmailFormat
        case .userNotFound:
            return .wrongCredentials
        case .sessionExpired:
            return .sessionExpired
        case .networkError(let error):
            return .networkError
        case .unknown(let message):
            return .unknown(NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: message]))
        }
    }
}

// MARK: - Migration Guide

/*
 MIGRATION GUIDE: De AuthenticationManager a AuthRepository
 
 El AuthenticationManager está marcado como DEPRECATED. Para código nuevo, usa AuthRepository directamente:
 
 1. En tu ViewModel:
 
    // Antiguo (DEPRECATED):
    @StateObject private var authManager = AuthenticationManager(authService: SupabaseAuthService())
 
    // Nuevo (RECOMENDADO):
    @StateObject private var authRepository = AuthFactory.shared.makeAuthRepository()
 
 2. Métodos equivalentes:
 
    Antiguo                                  | Nuevo
    ------------------------------------------|------------------------------------------
    authManager.login(email:password:)       | authRepository.login(email:password:)
    authManager.register(email:password:)    | authRepository.register(email:password:)
    authManager.sendPasswordReset(email:)    | authRepository.sendPasswordReset(email:)
    authManager.logout()                     | authRepository.logout()
    authManager.isAuthenticated              | authRepository.isAuthenticated
    authManager.isLoading                    | authRepository.isLoading
 
 3. Configurar el provider de autenticación en ContentView o App:
 
    .onAppear {
        // Configurar con Supabase
        AuthFactory.shared.configure(
            AuthConfiguration.supabase(
                url: ConfigurationManager.shared.supabaseURL,
                key: ConfigurationManager.shared.supabaseKey
            )
        )
        
        // O con Firebase (cuando esté implementado)
        // AuthFactory.shared.configure(AuthConfiguration.firebase(config: firebaseConfig))
        
        // O con Custom API
        // AuthFactory.shared.configure(AuthConfiguration.customAPI(baseURL: apiURL))
    }
 
 4. Beneficios de usar AuthRepository:
 
    - ✅ Abstracción completa del proveedor (Supabase, Firebase, Auth0, API custom)
    - ✅ Fácil de testear con mocks
    - ✅ Cambiar de proveedor sin tocar ViewModels (solo cambiar factory configuration)
    - ✅ Validación de email/password incluida
    - ✅ Manejo de errores consistente
    - ✅ Logging automático con OSLog
    - ✅ Gestión de sesiones (tokens, refresh, expiración)
 
 5. Para cambiar de Supabase a Firebase:
 
    a) Descomentar FirebaseAuthAdapter.swift
    b) Agregar Firebase SDK al proyecto
    c) En ContentView, cambiar:
       AuthFactory.shared.configure(AuthConfiguration.firebase(config: [...]))
    d) Listo! Todo sigue funcionando sin cambios en ViewModels
*/
