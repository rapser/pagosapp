import SwiftUI
import OSLog

struct ContentView: View {
    @Environment(SessionCoordinator.self) private var sessionCoordinator
    @Environment(PaymentSyncCoordinator.self) private var syncManager
    @Environment(AlertManager.self) private var alertManager
    @Environment(AppDependencies.self) private var dependencies
    @Environment(\.scenePhase) private var scenePhase

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "ContentView")
    private let foregroundCheckInterval: TimeInterval = 30

    @State private var showResetPassword = false
    @State private var resetToken: String?
    @State private var foregroundCheckTask: Task<Void, Never>?

    init() {
        // Configure UITabBar appearance once (global configuration)
        UITabBar.appearance().backgroundColor = UIColor(named: "AppBackground")
        UITabBar.appearance().unselectedItemTintColor = UIColor(named: "AppTextSecondary")
        UITabBar.appearance().tintColor = UIColor(named: "AppPrimary")
    }

    var body: some View {
        @Bindable var session = sessionCoordinator
        @Bindable var alert = alertManager
        ZStack {
            if sessionCoordinator.isAuthenticated {
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

                    SettingsView(
                        viewModel: dependencies.settingsDependencyContainer.makeSettingsViewModel()
                    )
                        .environment(alertManager)
                        .tabItem {
                            Label("Ajustes", systemImage: "gear")
                        }
                }
                // Removed onAppear - UITabBar.appearance() configured in init()
            } else {
                let loginViewModel = dependencies.authDependencyContainer.makeLoginViewModel()
                LoginView(loginViewModel: loginViewModel, onLoginSuccess: { session in
                    Task {
                        await sessionCoordinator.startSession()
                    }
                })
            }

            if sessionCoordinator.isLoading {
                LoadingView(message: nil)
            }
        }
        // Removed onAppear for calendar permissions - moved to App init
        .onChange(of: sessionCoordinator.isAuthenticated) { oldValue, newValue in
            if newValue {
                sessionCoordinator.updateLastActiveTimestamp()
                startForegroundCheckTimer()

                // Removed duplicate sync - SessionCoordinator.startSession() already handles sync
            } else if oldValue == true && newValue == false {
                stopForegroundCheckTimer()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UserDidLogin"))) { notification in
            // Fetch user profile when user logs in (respects Clean Architecture - no direct coupling)
            Task {
                // Extract userId from notification
                guard let userInfo = notification.userInfo,
                      let userId = userInfo["userId"] as? UUID else {
                    logger.warning("⚠️ UserDidLogin notification received but no userId found")
                    return
                }

                logger.info("📥 Fetching user profile for userId: \(userId.uuidString)")
                let fetchProfileUseCase = dependencies.userProfileDependencyContainer.makeFetchUserProfileUseCase()
                let result = await fetchProfileUseCase.execute(userId: userId)

                if case .success = result {
                    logger.info("✅ User profile fetched and saved during login")
                } else {
                    logger.error("❌ Failed to fetch user profile during login")
                }
            }
        }
        .onChange(of: scenePhase) { oldValue, newPhase in
            if newPhase == .active {
                if sessionCoordinator.isAuthenticated {
                    sessionCoordinator.checkSession()
                    startForegroundCheckTimer()
                }
            } else if newPhase == .background || newPhase == .inactive {
                // Combined .background and .inactive - same behavior
                if sessionCoordinator.isAuthenticated {
                    sessionCoordinator.updateLastActiveTimestamp()
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
        .alert("Sesión Cerrada por Inactividad", isPresented: $session.showInactivityAlert) {
            Button("Aceptar") {
                session.showInactivityAlert = false
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
                    // Extract access_token (used as reset token by Supabase)
                    if let accessToken = queryItems.first(where: { $0.name == "access_token" })?.value {
                        resetToken = accessToken
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
                if !Task.isCancelled && sessionCoordinator.isAuthenticated {
                    sessionCoordinator.checkSession()
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
        .environment(dependencies.sessionCoordinator)
        .environment(dependencies.paymentSyncCoordinator)
        .environment(AlertManager())
}
