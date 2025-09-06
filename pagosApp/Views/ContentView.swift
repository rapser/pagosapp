import SwiftUI
import Combine

struct ContentView: View {
    @StateObject private var authManager = AuthenticationManager()
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
                        return authManager.login(email: email, password: password)
                    },
                    onBiometricLogin: {
                        authManager.authenticateWithBiometrics()
                    },
                    isBiometricLoginEnabled: authManager.canUseBiometrics && SettingsManager.shared.isBiometricLockEnabled && authManager.hasLoggedInWithCredentials
                )
            }
        }
        .onAppear {
            // Solicitamos permisos al iniciar la app
            NotificationManager.shared.requestAuthorization()
            EventKitManager.shared.requestAccess { _ in }
            authManager.checkSession() // Comprobamos la sesión al iniciar
        }
        .onChange(of: scenePhase) { oldValue, newPhase in
            if newPhase == .active {
                authManager.checkSession()
                startForegroundCheckTimer() // Start timer when app becomes active
            } else if newPhase == .inactive || newPhase == .background {
                if authManager.isAuthenticated {
                    authManager.updateLastActiveTimestamp()
                }
                stopForegroundCheckTimer() // Stop timer when app goes to background/inactive
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
}