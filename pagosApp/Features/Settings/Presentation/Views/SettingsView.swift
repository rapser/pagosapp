import SwiftUI

struct SettingsView: View {
    @Environment(SessionCoordinator.self) private var sessionCoordinator
    @Environment(AlertManager.self) private var alertManager
    @Environment(SettingsStore.self) private var settingsStore
    @Environment(PaymentSyncCoordinator.self) private var syncManager

    @State private var showingSyncError = false
    @State private var syncErrorMessage = ""

    var body: some View {
        NavigationStack {
            Form {
                SyncSectionView(
                    onSyncTapped: handleSyncTapped,
                    onRetrySyncTapped: clearSyncError,
                    onDatabaseResetTapped: showDatabaseResetAlert
                )

                ProfileSectionView()

                SecuritySectionView()

                AboutSectionView()

                SessionSectionView(
                    onLogoutTapped: showLogoutAlert,
                    onUnlinkDeviceTapped: showUnlinkDeviceAlert
                )
            }
            .navigationTitle("Ajustes")
            .alert("Error de sincronización", isPresented: $showingSyncError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(syncErrorMessage)
            }
            .onAppear {
                Task {
                    await syncManager.updatePendingSyncCount()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("PaymentsDidSync"))) { _ in
                Task {
                    await syncManager.updatePendingSyncCount()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("PaymentDidChange"))) { _ in
                Task {
                    await syncManager.updatePendingSyncCount()
                }
            }
        }
    }

    private func handleSyncTapped() {
        Task {
            await performSync()
        }
    }
    
    private func performSync() async {
        do {
            try await syncManager.performSync()
        } catch {
            syncErrorMessage = error.localizedDescription
            showingSyncError = true
        }
    }
    
    private func clearSyncError() {
        syncManager.syncError = nil
        Task {
            await performSync()
        }
    }

    private func showDatabaseResetAlert() {
        alertManager.show(
            title: Text("Reparar Base de Datos"),
            message: Text("Esto eliminará todos los datos LOCALES de SwiftData y los volverá a descargar desde Supabase. Tus datos en el servidor NO se verán afectados. ¿Estás seguro?"),
            buttons: [
                AlertButton(title: Text("Reparar"), role: .destructive) {
                    Task {
                        let success = await syncManager.clearLocalDatabase(force: true)
                        if success {
                            alertManager.show(
                                title: Text("Base de Datos Reparada"),
                                message: Text("La aplicación se cerrará. Vuelve a abrirla para completar la reparación."),
                                buttons: [AlertButton(title: Text("OK"), role: .cancel) {
                                    exit(0)
                                }]
                            )
                        } else {
                            alertManager.show(
                                title: Text("Error"),
                                message: Text("No se pudo reparar la base de datos. Intenta reinstalar la aplicación."),
                                buttons: [AlertButton(title: Text("OK"), role: .cancel) { }]
                            )
                        }
                    }
                },
                AlertButton(title: Text("Cancelar"), role: .cancel) { }
            ]
        )
    }

    private func showLogoutAlert() {
        alertManager.show(
            title: Text("Cerrar Sesión"),
            message: Text("Tu sesión se cerrará pero tus datos permanecerán en este dispositivo. Al volver a iniciar sesión con la misma cuenta, todo estará aquí."),
            buttons: [
                AlertButton(title: Text("Cerrar Sesión"), role: .cancel) {
                    Task {
                        await sessionCoordinator.logout()
                    }
                },
                AlertButton(title: Text("Cancelar"), role: .cancel) { }
            ]
        )
    }

    private func showUnlinkDeviceAlert() {
        let pendingCount = syncManager.pendingSyncCount
        let warningMessage = pendingCount > 0
            ? "⚠️ Tienes \(pendingCount) pago(s) sin sincronizar.\n\nEsta acción eliminará TODOS tus datos locales (pagos, perfil y notificaciones) de este dispositivo de forma permanente.\n\n¿Estás completamente seguro?"
            : "Esta acción eliminará TODOS tus datos locales (pagos, perfil y notificaciones) de este dispositivo de forma permanente.\n\nTus datos en la nube están seguros y podrás descargarlos nuevamente al iniciar sesión en otro dispositivo.\n\n¿Estás seguro?"

        alertManager.show(
            title: Text("Desvincular Dispositivo"),
            message: Text(warningMessage),
            buttons: [
                AlertButton(title: Text("Desvincular"), role: .destructive) {
                    Task {
                        await sessionCoordinator.unlinkDevice()
                    }
                },
                AlertButton(title: Text("Cancelar"), role: .cancel) { }
            ]
        )
    }
}
