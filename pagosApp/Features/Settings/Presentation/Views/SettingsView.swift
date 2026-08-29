import SwiftUI

struct SettingsView: View {
    @Environment(AlertManager.self) private var alertManager
    @Environment(AppDependencies.self) private var dependencies
    @Environment(SettingsStore.self) private var settingsStore
    @Environment(AppSyncManager.self) private var syncManager
    @State private var viewModel: SettingsViewModel

    init(viewModel: SettingsViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            Form {
                // Perfil del usuario
                ProfileSectionView()

                // Historial, Estadísticas y Calendario (acceso desde Ajustes)
                Section {
                    NavigationLink(L10n.History.navTitle) {
                        PaymentHistoryView()
                    }
                    NavigationLink(L10n.Statistics.title) {
                        StatisticsView(
                            viewModel: dependencies.statisticsDependencyContainer.makeStatisticsViewModel()
                        )
                    }
                    NavigationLink(L10n.Tab.calendar) {
                        CalendarPaymentsView()
                    }
                } header: {
                    Text(L10n.Settings.sectionApp)
                }

                // Sincronización - agrupada en una subpantalla
                Section {
                    NavigationLink {
                        SettingsSyncView(
                            onSyncTapped: handleSyncTapped,
                            onRetrySyncTapped: handleRetrySyncTapped,
                            onDatabaseResetTapped: showDatabaseResetAlert
                        )
                    } label: {
                        HStack {
                            Text(L10n.Settings.sectionSync)
                            Spacer()
                            if syncManager.pendingSyncCount > 0 {
                                Text("\(syncManager.pendingSyncCount)")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color("AppPrimary"))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }

                // General (Seguridad, Legal, Acerca de, Datos) - agrupado en una subpantalla
                Section {
                    NavigationLink(L10n.Settings.General.rowTitle) {
                        SettingsGeneralView(onUnlinkDeviceTapped: showUnlinkDeviceAlert)
                    }
                }

                // Debug (Solo en builds de desarrollo)
                #if DEBUG
                Section("Debug") {
                    NavigationLink("Diagnóstico de Notificaciones") {
                        dependencies.settingsDependencyContainer.makeNotificationDebugView()
                    }
                }
                #endif

                // Sesión (Cerrar sesión)
                SessionSectionView(onLogoutTapped: showLogoutAlert)
            }
            .navigationTitle(L10n.Settings.title)
            .errorAlert(
                isPresented: $viewModel.showingSyncError,
                message: viewModel.syncErrorMessage,
                title: L10n.Settings.syncErrorTitle
            )
            .task {
                // Initial sync count update
                // Note: EventBus listeners are set up in ViewModel init
                await viewModel.updatePendingSyncCount()
            }
            .overlay {
                if viewModel.isLoading {
                    LoadingView(message: viewModel.loadingMessage)
                }
            }
        }
    }

    private func handleSyncTapped() {
        Task {
            await viewModel.handleSyncTapped()
        }
    }

    private func handleRetrySyncTapped() {
        Task {
            await viewModel.clearSyncError()
        }
    }

    private func showDatabaseResetAlert() {
        alertManager.show(
            title: Text(L10n.Settings.RepairDb.title),
            message: Text(L10n.Settings.RepairDb.confirmMessage),
            buttons: [
                AlertButton(title: Text(L10n.Settings.RepairDb.button), role: .destructive) {
                    Task {
                        let success = await viewModel.clearLocalDatabase()
                        if success {
                            alertManager.show(
                                title: Text(L10n.Settings.RepairDb.successTitle),
                                message: Text(L10n.Settings.RepairDb.successMessage),
                                buttons: [AlertButton(title: Text(L10n.General.ok), role: .cancel) {
                                    exit(0)
                                }]
                            )
                        } else {
                            alertManager.show(
                                title: Text(L10n.General.error),
                                message: Text(L10n.Settings.RepairDb.errorMessage),
                                buttons: [AlertButton(title: Text(L10n.General.ok), role: .cancel) { }]
                            )
                        }
                    }
                },
                AlertButton(title: Text(L10n.General.cancel), role: .cancel) { }
            ]
        )
    }

    private func showLogoutAlert() {
        alertManager.show(
            title: Text(L10n.Settings.Logout.title),
            message: Text(L10n.Settings.Logout.message),
            buttons: [
                AlertButton(title: Text(L10n.Settings.Logout.button), role: .destructive) {
                    Task {
                        await viewModel.logout()
                    }
                },
                AlertButton(title: Text(L10n.General.cancel), role: .cancel) { }
            ]
        )
    }

    private func showUnlinkDeviceAlert() {
        let warningMessage = L10n.Settings.Unlink.warning(pendingCount: viewModel.pendingSyncCount)
        alertManager.show(
            title: Text(L10n.Settings.Unlink.title),
            message: Text(warningMessage),
            buttons: [
                AlertButton(title: Text(L10n.Settings.Unlink.button), role: .destructive) {
                    Task {
                        await viewModel.unlinkDevice()
                    }
                },
                AlertButton(title: Text(L10n.General.cancel), role: .cancel) { }
            ]
        )
    }
}
