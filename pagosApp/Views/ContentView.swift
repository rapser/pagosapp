import SwiftUI
import SwiftData
import Combine
import Supabase
import OSLog

struct ContentView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @EnvironmentObject private var passwordRecoveryUseCase: PasswordRecoveryUseCase
    @StateObject private var alertManager = AlertManager()
    @StateObject private var syncManager = PaymentSyncManager.shared
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "ContentView")

    // Timer for foreground session checking
    @State private var foregroundCheckTimer: AnyCancellable?
    private let foregroundCheckInterval: TimeInterval = 30 // Check every 30 seconds

    // Password reset
    @State private var showResetPassword = false
    @State private var resetAccessToken: String?
    @State private var resetRefreshToken: String?

    var body: some View {
        ZStack {
            if authManager.isAuthenticated {
                TabView {
                    PaymentsListView()
                        .tabItem {
                            Label("Pagos", systemImage: "list.bullet.rectangle.portrait")
                        }

                    CalendarPaymentsView()
                        .environmentObject(alertManager)
                        .tabItem {
                            Label("Calendario", systemImage: "calendar")
                        }

                    PaymentHistoryView()
                        .tabItem {
                            Label("Historial", systemImage: "clock.arrow.circlepath")
                        }

                    StatisticsView()
                        .tabItem {
                            Label("Estadísticas", systemImage: "chart.pie.fill")
                        }

                    SettingsView()
                        .environmentObject(authManager)
                        .environmentObject(alertManager)
                        .tabItem {
                            Label("Ajustes", systemImage: "gear")
                        }
                }
                .onAppear {
                    UITabBar.appearance().backgroundColor = UIColor(named: "AppBackground")
                    UITabBar.appearance().unselectedItemTintColor = UIColor(named: "AppTextSecondary")
                    UITabBar.appearance().tintColor = UIColor(named: "AppPrimary")
                }
            } else {
                let biometricEnabled = authManager.canUseBiometrics && SettingsManager.shared.isBiometricLockEnabled && authManager.hasLoggedInWithCredentials

                LoginView(
                    onLogin: { email, password in
                        await authManager.login(email: email, password: password)
                    },
                    onBiometricLogin: {
                        await authManager.authenticateWithBiometrics()
                    },
                    isBiometricLoginEnabled: biometricEnabled
                )
                .environmentObject(authManager) // Inject authManager into LoginView and its hierarchy
            }
            
            // Show loading view if authManager.isLoading is true
            if authManager.isLoading {
                LoadingView()
            }
        }
        .onAppear {
            // Solicitamos permisos al iniciar la app
            NotificationManager.shared.requestAuthorization()
            EventKitManager.shared.requestAccess { _ in }
            // authManager.checkSession() is now called by onChange(of: isAuthenticated) or scenePhase .active
        }
        .onChange(of: authManager.isAuthenticated) { oldValue, newValue in
            if newValue { // User just became authenticated
                authManager.startInactivityTimer() // Start the timer
                startForegroundCheckTimer() // Start foreground check

                // Perform initial sync and fetch profile in parallel (non-blocking)
                // Use Task instead of Task.detached to stay in MainActor context
                Task(priority: .utility) {
                    await syncManager.performInitialSyncIfNeeded(modelContext: modelContext, isAuthenticated: true)
                }
                
                // Fetch and save user profile in background
                Task(priority: .background) {
                    _ = await UserProfileService.shared.fetchAndSaveProfile(supabaseClient: authManager.authService.client, modelContext: modelContext)
                }
            } else if oldValue == true && newValue == false { // User explicitly logged out (not initial state)
                stopForegroundCheckTimer() // Stop foreground check

                // Clear user profile from local storage
                UserProfileService.shared.clearLocalProfile(modelContext: modelContext)

                // Only clear database if user was previously authenticated
                // This clears ONLY local SwiftData, NEVER touches Supabase
                syncManager.clearLocalDatabase(modelContext: modelContext)
            }
        }
        .onChange(of: scenePhase) { oldValue, newPhase in
            if newPhase == .active {
                // Only check session if already authenticated, otherwise it's handled by login/registration
                if authManager.isAuthenticated {
                    authManager.checkSession()
                    startForegroundCheckTimer() // Start timer when app becomes active
                }
            } else if newPhase == .background {
                // Update timestamp when going to background to track inactivity
                if authManager.isAuthenticated {
                    authManager.updateLastActiveTimestamp()
                }
                stopForegroundCheckTimer() // Stop timer when app goes to background
            } else if newPhase == .inactive {
                // For inactive, just update timestamp for inactivity timer
                if authManager.isAuthenticated {
                    authManager.updateLastActiveTimestamp()
                }
                stopForegroundCheckTimer() // Stop timer when app goes inactive
            }
        }
        .alert(isPresented: $alertManager.isPresented) {
            if alertManager.buttons.count == 1 {
                return Alert(
                    title: alertManager.title,
                    message: alertManager.message,
                    dismissButton: .default(alertManager.buttons[0].title, action: {
                        alertManager.buttons[0].action()
                    })
                )
            } else if alertManager.buttons.count == 2 {
                return Alert(
                    title: alertManager.title,
                    message: alertManager.message,
                    primaryButton: .default(alertManager.buttons[0].title, action: {
                        alertManager.buttons[0].action()
                    }),
                    secondaryButton: .cancel(alertManager.buttons[1].title, action: {
                        alertManager.buttons[1].action()
                    })
                )
            } else {
                // Fallback for no buttons or more than 2 (shouldn't happen with current usage)
                return Alert(title: alertManager.title, message: alertManager.message)
            }
        }
        .alert("Sesión Cerrada por Inactividad", isPresented: $authManager.showInactivityAlert) {
            Button("Aceptar") {
                authManager.showInactivityAlert = false
            }
        } message: {
            Text("Tu sesión ha sido cerrada automáticamente debido a 1 semana de inactividad.")
        }
        .sheet(isPresented: $showResetPassword) {
            if let accessToken = resetAccessToken, let refreshToken = resetRefreshToken {
                ResetPasswordView(accessToken: accessToken, refreshToken: refreshToken, passwordRecoveryUseCase: passwordRecoveryUseCase)
                    .environmentObject(alertManager)
            }
        }
        .onOpenURL { url in
            logger.info("Deep link opened: \(url.absoluteString)")
            if url.scheme == "pagosapp" && url.host == "reset-password" {
                logger.info("Processing password reset deep link")
                // Parse query parameters
                if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                   let queryItems = components.queryItems {
                    // Check for code (PKCE flow) or direct tokens
                    var code: String?
                    var accessToken: String?
                    var refreshToken: String?

                    for item in queryItems {
                        if item.name == "code" {
                            code = item.value
                            logger.info("Found code for PKCE flow")
                        } else if item.name == "access_token" {
                            accessToken = item.value
                            logger.info("Found access token")
                        } else if item.name == "refresh_token" {
                            refreshToken = item.value
                            logger.info("Found refresh token")
                        }
                    }

                    if let authCode = code {
                        // PKCE flow: exchange code for session
                        Task {
                            do {
                                let session = try await supabaseClient.auth.exchangeCodeForSession(authCode: authCode)
                                resetAccessToken = session.accessToken
                                resetRefreshToken = session.refreshToken
                                showResetPassword = true
                                logger.info("Exchanged code for session, showing reset password view")
                            } catch {
                                logger.error("Failed to exchange code for session: \(error)")
                            }
                        }
                    } else if let access = accessToken, let refresh = refreshToken {
                        // Direct tokens flow
                        resetAccessToken = access
                        resetRefreshToken = refresh
                        showResetPassword = true
                        logger.info("Using direct tokens, showing reset password view")
                    } else {
                        logger.error("Missing code or tokens in URL")
                    }
                } else {
                    logger.error("Failed to parse URL components")
                }
            } else {
                logger.info("URL does not match expected scheme/host")
            }
        }
        .withErrorHandling() // Global error handling
    }
    
    private func startForegroundCheckTimer() {
        // Ensure only one timer is active
        stopForegroundCheckTimer()
        foregroundCheckTimer = Timer.publish(every: foregroundCheckInterval, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                if authManager.isAuthenticated {
                    authManager.checkSession()
                }
            }
    }
    
    private func stopForegroundCheckTimer() {
        foregroundCheckTimer?.cancel()
        foregroundCheckTimer = nil
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthenticationManager(authService: SupabaseAuthService(client: SupabaseClient(supabaseURL: URL(string: "https://example.com") ?? URL(filePath: "/"), supabaseKey: "dummy_key"))))
        .environmentObject(AlertManager())
}
