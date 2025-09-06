import SwiftUI
import Combine
import Supabase

struct ContentView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @StateObject private var alertManager = AlertManager()
    @Environment(\.scenePhase) private var scenePhase
    
    // Timer for foreground session checking
    @State private var foregroundCheckTimer: AnyCancellable?
    private let foregroundCheckInterval: TimeInterval = 30 // Check every 30 seconds

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
                .onAppear { // Apply appearance changes when TabView appears
                    UITabBar.appearance().backgroundColor = .white
                }
            } else {
                LoginView(
                    onLogin: { email, password in
                        await authManager.login(email: email, password: password)
                    },
                    onBiometricLogin: {
                        await authManager.authenticateWithBiometrics()
                    },
                    isBiometricLoginEnabled: authManager.canUseBiometrics && SettingsManager.shared.isBiometricLockEnabled && authManager.hasLoggedInWithCredentials
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
            } else { // User just became unauthenticated (logged out)
                stopForegroundCheckTimer() // Stop foreground check
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
                // Logout when app goes to background (as per user's strict request)
                Task { await authManager.logout() }
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
            Text("Tu sesión ha sido cerrada automáticamente debido a 5 minutos de inactividad.")
        }
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
        .environmentObject(AuthenticationManager(authService: SupabaseAuthService(client: SupabaseClient(supabaseURL: URL(string: "https://example.com")!, supabaseKey: "dummy_key"))))
        .environmentObject(AlertManager())
}