import SwiftUI

/// Root view for authenticated users - displays the main TabView
struct AuthenticatedRootView: View {
    @Environment(AppDependencies.self) private var dependencies
    @Environment(AlertManager.self) private var alertManager

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

            CardsListView(
                viewModel: dependencies.cardDependencyContainer.makeCardsListViewModel()
            )
                .environment(alertManager)
                .tabItem {
                    Label(L10n.Tab.cards, systemImage: "creditcard.fill")
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
