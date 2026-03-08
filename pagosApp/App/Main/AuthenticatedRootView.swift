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
                    Label(L10n.Tab.payments, systemImage: "list.bullet.rectangle.portrait")
                }

            RemindersListView()
                .tabItem {
                    Label(L10n.Tab.reminders, systemImage: "bell.badge")
                }

            CalendarPaymentsView()
                .environment(alertManager)
                .tabItem {
                    Label(L10n.Tab.calendar, systemImage: "calendar")
                }

            SettingsView(
                viewModel: dependencies.settingsDependencyContainer.makeSettingsViewModel()
            )
                .environment(alertManager)
                .tabItem {
                    Label(L10n.Tab.settings, systemImage: "gear")
                }
        }
    }
}
