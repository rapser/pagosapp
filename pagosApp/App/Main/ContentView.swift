import SwiftUI
import OSLog

struct ContentView: View {
    @Environment(AuthenticationManager.self) private var authManager
    @Environment(PaymentSyncCoordinator.self) private var syncManager
    @Environment(SettingsManager.self) private var settingsManager
    @Environment(AlertManager.self) private var alertManager
    @Environment(\.dependencies) private var dependencies
    @Environment(\.scenePhase) private var scenePhase

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "ContentView")
    private let foregroundCheckInterval: TimeInterval = 30

    @State private var showResetPassword = false
    @State private var resetToken: String?
    @State private var foregroundCheckTask: Task<Void, Never>?

    var body: some View {
        @Bindable var auth = authManager
        @Bindable var alert = alertManager
        ZStack {
            if authManager.isSessionActive {
                TabView {
                    PaymentsListView()
                        .tabItem {
                            Label("Pagos", systemImage: "list.bullet.rectangle.portrait")
                        }

                    CalendarPaymentsView()
                        .environment(alertManager)
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
                        .environment(authManager)
                        .environment(alertManager)
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
                let loginViewModel = dependencies.authDependencyContainer.makeLoginViewModel()
                LoginView(loginViewModel: loginViewModel)
            }

            if authManager.isLoading {
                LoadingView()
            }
        }
        .onAppear {
            dependencies.eventKitManager.requestAccess { _ in }
        }
        .onChange(of: authManager.isAuthenticated) { oldValue, newValue in
            if newValue {
                authManager.startInactivityTimer()
                startForegroundCheckTimer()

                Task(priority: .utility) {
                    await syncManager.performInitialSyncIfNeeded(isAuthenticated: true)
                }

                Task(priority: .background) {
                    if let userId = authManager.supabaseClient?.auth.currentUser?.id {
                        let fetchUseCase = dependencies.userProfileDependencyContainer.makeFetchUserProfileUseCase()
                        _ = await fetchUseCase.execute(userId: userId)
                    }
                }
            } else if oldValue == true && newValue == false {
                stopForegroundCheckTimer()
            }
        }
        .onChange(of: scenePhase) { oldValue, newPhase in
            if newPhase == .active {
                if authManager.isAuthenticated {
                    authManager.checkSession()
                    startForegroundCheckTimer()
                }
            } else if newPhase == .background {
                if authManager.isAuthenticated {
                    authManager.updateLastActiveTimestamp()
                }
                stopForegroundCheckTimer()
            } else if newPhase == .inactive {
                if authManager.isAuthenticated {
                    authManager.updateLastActiveTimestamp()
                }
                stopForegroundCheckTimer()
            }
        }
        .alert(isPresented: $alert.isPresented) {
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
                return Alert(title: alertManager.title, message: alertManager.message)
            }
        }
        .alert("Sesión Cerrada por Inactividad", isPresented: $auth.showInactivityAlert) {
            Button("Aceptar") {
                auth.showInactivityAlert = false
            }
        } message: {
            Text("Tu sesión ha sido cerrada automáticamente debido a 1 semana de inactividad.")
        }
        .sheet(isPresented: $showResetPassword) {
            if let token = resetToken {
                ResetPasswordView(
                    token: token,
                    viewModel: dependencies.authDependencyContainer.makeResetPasswordViewModel()
                )
                .environment(alertManager)
            }
        }
        .onOpenURL { url in
            logger.info("Deep link opened: \(url.absoluteString)")
            if url.scheme == "pagosapp" && url.host == "reset-password" {
                logger.info("Processing password reset deep link")
                if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                   let queryItems = components.queryItems {
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

                    // Extract access_token (used as reset token by Supabase)
                    if let token = accessToken {
                        resetToken = token
                        showResetPassword = true
                        logger.info("Password reset token found")
                    } else {
                        logger.error("No access_token found in URL")
                    }
                } else {
                    logger.error("Failed to parse URL components")
                }
            } else {
                logger.info("URL does not match expected scheme/host")
            }
        }
    }
    
    private func startForegroundCheckTimer() {
        stopForegroundCheckTimer()

        foregroundCheckTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(foregroundCheckInterval))
                if !Task.isCancelled && authManager.isAuthenticated {
                    authManager.checkSession()
                }
            }
        }
    }
    
    private func stopForegroundCheckTimer() {
        foregroundCheckTask?.cancel()
        foregroundCheckTask = nil
    }
}

#Preview {
    let dependencies = AppDependencies.mock()

    ContentView()
        .environment(dependencies.authenticationManager)
        .environment(dependencies.paymentSyncCoordinator)
        .environment(dependencies.settingsManager)
        .environment(AlertManager())
}
