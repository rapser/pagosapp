import SwiftUI

/// Root view for authenticated users - displays the main TabView
struct AuthenticatedRootView: View {
    @Environment(AppDependencies.self) private var dependencies
    @Environment(AlertManager.self) private var alertManager

    init() {
        // Configure UITabBar appearance once (global configuration)
        UITabBar.appearance().backgroundColor = UIColor(named: "AppBackground")
        UITabBar.appearance().unselectedItemTintColor = UIColor(named: "AppTextSecondary")
        UITabBar.appearance().tintColor = UIColor(named: "AppPrimary")
    }

    var body: some View {
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
    }
}
