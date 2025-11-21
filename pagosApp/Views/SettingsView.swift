import SwiftUI
import Combine
import SwiftData

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var alertManager: AlertManager
    @StateObject private var settingsManager = SettingsManager.shared
    @StateObject private var syncManager = PaymentSyncManager.shared
    @Environment(\.modelContext) private var modelContext

    @State private var showingSyncError = false
    @State private var syncErrorMessage = ""

    var body: some View {
        NavigationView {
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
                    if !authManager.isAuthenticated {
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
                                    .foregroundColor(authManager.isAuthenticated ? Color("AppPrimary") : Color("AppTextSecondary"))
                            }
                            Text(syncManager.isSyncing ? "Sincronizando..." : "Sincronizar ahora")
                                .foregroundColor(syncManager.isSyncing ? Color("AppTextSecondary") : (authManager.isAuthenticated ? Color("AppPrimary") : Color("AppTextSecondary")))
                        }
                    }
                    .disabled(syncManager.isSyncing || !authManager.isAuthenticated)
                }

                Section(header: Text("Seguridad").foregroundColor(Color("AppTextPrimary"))) {
                    NavigationLink(destination: BiometricSettingsView().environmentObject(authManager)) {
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

    private func showLogoutAlert() {
        let hasFaceIDEnabled = settingsManager.isBiometricLockEnabled && authManager.canUseBiometrics
        alertManager.show(
            title: Text("Cerrar Sesión"),
            message: Text("¿Estás seguro de que quieres cerrar la sesión?"),
            buttons: [
                AlertButton(title: Text("Aceptar"), role: .destructive) {
                    Task {
                        // If Face ID is enabled, keep the session so user can login with Face ID
                        await authManager.logout(keepSession: hasFaceIDEnabled)
                    }
                },
                AlertButton(title: Text("Cancelar"), role: .cancel) { }
            ]
        )
    }
}

#Preview {
    // Dummy AuthenticationService for preview
    class MockAuthService: AuthenticationService {
        func signUp(email: String, password: String) async throws {
            
        }
        
        var isAuthenticatedPublisher: AnyPublisher<Bool, Never> { Just(true).eraseToAnyPublisher() }
        var isAuthenticated: Bool = true
        func signIn(email: String, password: String) async throws { }
        func signOut() async throws { }
        func getCurrentUser() async throws -> String? { return "preview@example.com" }
    }

    return SettingsView()
        .environmentObject(AuthenticationManager(authService: MockAuthService()))
        .environmentObject(AlertManager())
}