import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(AuthenticationManager.self) private var authManager
    @Environment(AlertManager.self) private var alertManager
    @Environment(\.modelContext) private var modelContext

    @State private var showingSyncError = false
    @State private var syncErrorMessage = ""

    // Direct access to singletons (no @State needed)
    private var settingsManager: SettingsManager { .shared }
    private var syncManager: PaymentSyncManager { .shared }

    var body: some View {
        NavigationStack {
            Form {
                // Sync Section
                Section(header: Text("Sincronización").foregroundColor(Color("AppTextPrimary"))) {
                    // Pending sync count
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .foregroundColor(Color("AppPrimary"))
                        Text("Pagos sin sincronizar")
                            .foregroundColor(Color("AppTextPrimary"))
                        Spacer()
                        if syncManager.pendingSyncCount > 0 {
                            Text("\(syncManager.pendingSyncCount)")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color("AppPrimary"))
                                .clipShape(Capsule())
                        } else {
                            Text("Todo sincronizado")
                                .foregroundColor(Color("AppTextSecondary"))
                                .font(.subheadline)
                        }
                    }

                    // Last sync date
                    if let lastSync = syncManager.lastSyncDate {
                        HStack {
                            Text("Última sincronización")
                                .foregroundColor(Color("AppTextPrimary"))
                            Spacer()
                            Text(lastSync, style: .relative)
                                .foregroundColor(Color("AppTextSecondary"))
                                .font(.subheadline)
                        }
                    }

                    // Authentication message if not logged in
                    if !authManager.isAuthenticated && !authManager.isSessionActive {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(Color("AppTextSecondary"))
                            Text("Inicia sesión para sincronizar")
                                .foregroundColor(Color("AppTextSecondary"))
                                .font(.subheadline)
                        }
                    }

                    // Sync button
                    Button {
                        Task {
                            await performSync()
                        }
                    } label: {
                        HStack {
                            if syncManager.isSyncing {
                                ProgressView()
                                    .tint(Color("AppPrimary"))
                            } else {
                                Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                                    .foregroundColor((authManager.isAuthenticated || authManager.isSessionActive) ? Color("AppPrimary") : Color("AppTextSecondary"))
                            }
                            Text(syncManager.isSyncing ? "Sincronizando..." : "Sincronizar ahora")
                                .foregroundColor(syncManager.isSyncing ? Color("AppTextSecondary") : ((authManager.isAuthenticated || authManager.isSessionActive) ? Color("AppPrimary") : Color("AppTextSecondary")))
                        }
                    }
                    .disabled(syncManager.isSyncing || (!authManager.isAuthenticated && !authManager.isSessionActive))

                    // Clear sync error button (only show if there are sync errors)
                    if syncManager.syncError != nil {
                        Button {
                            clearSyncError()
                        } label: {
                            HStack {
                                Image(systemName: "arrow.clockwise.circle.fill")
                                    .foregroundColor(.blue)
                                Text("Reintentar sincronización")
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        // Database reset button (last resort)
                        Button {
                            showDatabaseResetAlert()
                        } label: {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text("Reparar base de datos")
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                }

                Section(header: Text("Perfil").foregroundColor(Color("AppTextPrimary"))) {
                    if (authManager.isAuthenticated || authManager.isSessionActive), let client = authManager.supabaseClient {
                        NavigationLink(destination: UserProfileView(supabaseClient: client, modelContext: modelContext)) {
                            HStack {
                                Image(systemName: "person.circle.fill")
                                    .foregroundColor(Color("AppPrimary"))
                                Text("Mi Perfil")
                                    .foregroundColor(Color("AppTextPrimary"))
                            }
                        }
                    } else {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(Color("AppTextSecondary"))
                            Text("Mi Perfil")
                                .foregroundColor(Color("AppTextSecondary"))
                            Spacer()
                            Text("Inicia sesión")
                                .font(.caption)
                                .foregroundColor(Color("AppTextSecondary"))
                        }
                    }
                }

                Section(header: Text("Seguridad").foregroundColor(Color("AppTextPrimary"))) {
                    NavigationLink(destination: BiometricSettingsView().environment(authManager)) {
                        HStack {
                            Image(systemName: "faceid")
                                .foregroundColor(Color("AppPrimary"))
                            Text("Autenticación Biométrica")
                                .foregroundColor(Color("AppTextPrimary"))
                        }
                    }
                }

                Section(header: Text("Acerca de").foregroundColor(Color("AppTextPrimary"))) {
                    HStack {
                        Text("Versión")
                            .foregroundColor(Color("AppTextPrimary"))
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(Color("AppTextSecondary"))
                    }
                }

                Section {
                    Button("Cerrar Sesión", role: .destructive) {
                        showLogoutAlert()
                    }
                }
            }
            .navigationTitle("Ajustes")
            .alert("Error de sincronización", isPresented: $showingSyncError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(syncErrorMessage)
            }
            .onAppear {
                syncManager.updatePendingSyncCount(modelContext: modelContext)
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("PaymentsDidSync"))) { _ in
                // Refresh pending count when payments are synced
                syncManager.updatePendingSyncCount(modelContext: modelContext)
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("PaymentDidChange"))) { _ in
                // Refresh pending count when a payment changes
                syncManager.updatePendingSyncCount(modelContext: modelContext)
            }
        }
    }
    
    private func performSync() async {
        do {
            try await syncManager.performManualSync(modelContext: modelContext, isAuthenticated: authManager.isAuthenticated)
        } catch {
            syncErrorMessage = error.localizedDescription
            showingSyncError = true
        }
    }
    
    private func clearSyncError() {
        // Clear the sync error and try again
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
                    if syncManager.forceDatabaseReset() {
                        alertManager.show(
                            title: Text("Base de Datos Reparada"),
                            message: Text("La aplicación se cerrará. Vuelve a abrirla para completar la reparación."),
                            buttons: [AlertButton(title: Text("OK"), role: .cancel) {
                                // Force app restart by crashing (not ideal but effective)
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
                },
                AlertButton(title: Text("Cancelar"), role: .cancel) { }
            ]
        )
    }

    private func showLogoutAlert() {
        alertManager.show(
            title: Text("Cerrar Sesión"),
            message: Text("¿Estás seguro de que quieres cerrar la sesión?"),
            buttons: [
                AlertButton(title: Text("Aceptar"), role: .destructive) {
                    Task {
                        // Always close Supabase session and clear local data
                        await authManager.logout(modelContext: modelContext)
                    }
                },
                AlertButton(title: Text("Cancelar"), role: .cancel) { }
            ]
        )
    }
}
