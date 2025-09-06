import Foundation
import LocalAuthentication
import Combine

@MainActor // Added @MainActor
class AuthenticationManager: ObservableObject {
    private let authService: AuthenticationService
    private var cancellables = Set<AnyCancellable>()
    
    private let hasLoggedInWithCredentialsKey = "hasLoggedInWithCredentials"
    private let lastActiveTimestampKey = "lastActiveTimestamp"
    private let sessionTimeoutInSeconds: TimeInterval = 300
    
    @Published var isAuthenticated = false
    @Published var canUseBiometrics = false
    @Published var showInactivityAlert = false
    @Published var hasLoggedInWithCredentials = false
    @Published var isLoading: Bool = false // Added isLoading property
    
    init(authService: AuthenticationService) {
        self.authService = authService
        self.hasLoggedInWithCredentials = UserDefaults.standard.bool(forKey: hasLoggedInWithCredentialsKey)
        checkBiometricAvailability()
        
        // Observe changes from the injected AuthenticationService
        authService.isAuthenticatedPublisher
            .sink { [weak self] isAuthenticated in
                guard let self = self else { return }
                self.isAuthenticated = isAuthenticated
                print("AuthManager: isAuthenticated updated to \(isAuthenticated)")
                
                // If Supabase reports authenticated, but our local flag says no credential login yet,
                // it means a stale session from Keychain. Force logout.
                if isAuthenticated && !self.hasLoggedInWithCredentials {
                    print("AuthManager: Stale session detected. Forcing logout.")
                    Task { await self.logout() }
                }
            }
            .store(in: &cancellables)
    }
    
    private func checkBiometricAvailability() {
        let context = LAContext()
        var error: NSError?
        canUseBiometrics = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    @MainActor
    func login(email: String, password: String) async -> AuthenticationError? {
        guard EmailValidator.isValidEmail(email) else {
            return .invalidEmailFormat
        }
        
        isLoading = true // Set loading to true
        defer { isLoading = false } // Ensure loading is set to false when function exits

        do {
            print("AuthManager: Attempting login for \(email)")
            try await authService.signIn(email: email, password: password)
            self.hasLoggedInWithCredentials = true
            UserDefaults.standard.set(true, forKey: self.hasLoggedInWithCredentialsKey)
            print("AuthManager: Login successful. hasLoggedInWithCredentials set to true.")
            return nil
        } catch let authError as AuthenticationError {
            print("AuthManager: Login failed with auth error: \(authError.localizedDescription)")
            return authError
        } catch {
            print("AuthManager: Login failed with unknown error: \(error.localizedDescription)")
            return .unknown(error)
        }
    }
    
    @MainActor
    func register(email: String, password: String) async -> AuthenticationError? {
        guard EmailValidator.isValidEmail(email) else {
            return .invalidEmailFormat
        }
        
        isLoading = true // Set loading to true
        defer { isLoading = false } // Ensure loading is set to false when function exits

        do {
            print("AuthManager: Attempting registration for \(email)")
            try await authService.signUp(email: email, password: password)
            // After successful registration, user is usually signed in automatically by Supabase
            // The isAuthenticatedPublisher will update self.isAuthenticated
            self.hasLoggedInWithCredentials = true
            UserDefaults.standard.set(true, forKey: self.hasLoggedInWithCredentialsKey)
            print("AuthManager: Registration successful. hasLoggedInWithCredentials set to true.")
            return nil
        } catch let authError as AuthenticationError {
            print("AuthManager: Registration failed with auth error: \(authError.localizedDescription)")
            return authError
        } catch {
            print("AuthManager: Registration failed with unknown error: \(error.localizedDescription)")
            return .unknown(error)
        }
    }
    
    @MainActor
    func authenticateWithBiometrics() async {
        guard canUseBiometrics else { return }
        
        isLoading = true // Set loading to true
        // defer { isLoading = false } // Removed defer here, handled in DispatchQueue.main.async

        let context = LAContext()
        let reason = "Inicia sesión con Face ID para acceder a tus pagos."

        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
            DispatchQueue.main.async {
                if success {
                    print("AuthManager: Biometric authentication successful.")
                    // Biometric success. The authService.isAuthenticatedPublisher will update self.isAuthenticated
                } else {
                    print("AuthManager: Biometric authentication failed: \(authenticationError?.localizedDescription ?? "Unknown error")")
                }
                self.isLoading = false // Set loading to false after biometric evaluation
            }
        }
    }
    
    @MainActor
    func logout(inactivity: Bool = false) async {
        print("AuthManager: Attempting logout (inactivity: \(inactivity))")
        do {
            try await authService.signOut()
            // Explicitly clear hasLoggedInWithCredentials on logout
            self.hasLoggedInWithCredentials = false
            UserDefaults.standard.set(false, forKey: self.hasLoggedInWithCredentialsKey)
            UserDefaults.standard.removeObject(forKey: self.lastActiveTimestampKey)
            if inactivity {
                self.showInactivityAlert = true
                print("AuthManager: showInactivityAlert set to true.")
            }
            print("AuthManager: Logout successful. Local flags cleared.")
        } catch let authError as AuthenticationError {
            // Handle logout error, but still clear local state
            print("AuthManager: Logout failed with auth error: \(authError.localizedDescription)")
            self.hasLoggedInWithCredentials = false
            UserDefaults.standard.set(false, forKey: self.hasLoggedInWithCredentialsKey)
            UserDefaults.standard.removeObject(forKey: self.lastActiveTimestampKey)
        } catch {
            print("AuthManager: Unknown logout error: \(error.localizedDescription)")
            self.hasLoggedInWithCredentials = false
            UserDefaults.standard.set(false, forKey: self.hasLoggedInWithCredentialsKey)
            UserDefaults.standard.removeObject(forKey: self.lastActiveTimestampKey)
        }
    }
    
    func checkSession() {
        print("AuthManager: checkSession() called.")
        if let lastActiveTimestamp = UserDefaults.standard.object(forKey: lastActiveTimestampKey) as? Date {
            let elapsedTime = Date().timeIntervalSince(lastActiveTimestamp)
            print("AuthManager: lastActiveTimestamp: \(lastActiveTimestamp), elapsedTime: \(elapsedTime)s")
            if elapsedTime > sessionTimeoutInSeconds {
                print("AuthManager: Inactivity timeout reached. Logging out.")
                Task { await logout(inactivity: true) }
            } 
        } else {
            print("AuthManager: No lastActiveTimestamp found. Starting inactivity timer.")
            startInactivityTimer()
        }
    }
    
    func startInactivityTimer() {
        updateLastActiveTimestamp()
    }

    func updateLastActiveTimestamp() {
        UserDefaults.standard.set(Date(), forKey: lastActiveTimestampKey)
        print("AuthManager: lastActiveTimestamp updated to \(Date())")
    }
}
