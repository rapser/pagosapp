import SwiftUI

/// Root coordinator view - handles navigation between Login and authenticated app
struct ContentView: View {
    @Environment(SessionCoordinator.self) private var sessionCoordinator
    @Environment(AlertManager.self) private var alertManager
    @Environment(AppDependencies.self) private var dependencies

    var body: some View {
        @Bindable var session = sessionCoordinator
        @Bindable var alert = alertManager

        ZStack {
            // Main navigation: Login or Authenticated TabView
            if sessionCoordinator.isAuthenticated {
                AuthenticatedRootView()
            } else {
                let loginViewModel = dependencies.authDependencyContainer.makeLoginViewModel()
                LoginView(loginViewModel: loginViewModel, onLoginSuccess: { session in
                    Task {
                        await sessionCoordinator.startSession()
                    }
                })
            }

            // Global loading overlay
            if sessionCoordinator.isLoading {
                LoadingView(message: nil)
            }
        }
        // Apply modular handlers via ViewModifiers
        .handleAppLifecycle()
        .loadUserProfileOnLogin()
        .handleDeepLinks()
        // Global alerts
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
    }
}

#Preview {
    let dependencies = AppDependencies.mock()

    ContentView()
        .environment(dependencies.sessionCoordinator)
        .environment(dependencies.paymentSyncCoordinator)
        .environment(AlertManager())
}
