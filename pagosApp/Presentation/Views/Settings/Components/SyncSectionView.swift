import SwiftUI
import SwiftData

struct SyncSectionView: View {
    @Environment(AuthenticationManager.self) private var authManager
    @Environment(PaymentSyncCoordinator.self) private var syncManager

    let onSyncTapped: () -> Void
    let onRetrySyncTapped: () -> Void
    let onDatabaseResetTapped: () -> Void

    var body: some View {
        Section(header: Text("Sincronización").foregroundColor(Color("AppTextPrimary"))) {
            PendingSyncCountRow(pendingSyncCount: syncManager.pendingSyncCount)

            if let lastSync = syncManager.lastSyncDate {
                LastSyncDateRow(lastSyncDate: lastSync)
            }

            if !authManager.isAuthenticated && !authManager.isSessionActive {
                AuthenticationRequiredRow()
            }

            SyncButton(
                isSyncing: syncManager.isSyncing,
                isAuthenticated: authManager.isAuthenticated || authManager.isSessionActive,
                action: onSyncTapped
            )

            if syncManager.syncError != nil {
                RetrySyncButton(action: onRetrySyncTapped)
                DatabaseResetButton(action: onDatabaseResetTapped)
            }
        }
    }
}

private struct PendingSyncCountRow: View {
    let pendingSyncCount: Int

    var body: some View {
        HStack {
            Image(systemName: "arrow.triangle.2.circlepath")
                .foregroundColor(Color("AppPrimary"))
            Text("Pagos sin sincronizar")
                .foregroundColor(Color("AppTextPrimary"))
            Spacer()
            if pendingSyncCount > 0 {
                Text("\(pendingSyncCount)")
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
    }
}

private struct LastSyncDateRow: View {
    let lastSyncDate: Date

    var body: some View {
        HStack {
            Text("Última sincronización")
                .foregroundColor(Color("AppTextPrimary"))
            Spacer()
            Text(lastSyncDate, style: .relative)
                .foregroundColor(Color("AppTextSecondary"))
                .font(.subheadline)
        }
    }
}

private struct AuthenticationRequiredRow: View {
    var body: some View {
        HStack {
            Image(systemName: "info.circle")
                .foregroundColor(Color("AppTextSecondary"))
            Text("Inicia sesión para sincronizar")
                .foregroundColor(Color("AppTextSecondary"))
                .font(.subheadline)
        }
    }
}

private struct SyncButton: View {
    let isSyncing: Bool
    let isAuthenticated: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                if isSyncing {
                    ProgressView()
                        .tint(Color("AppPrimary"))
                } else {
                    Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                        .foregroundColor(isAuthenticated ? Color("AppPrimary") : Color("AppTextSecondary"))
                }
                Text(isSyncing ? "Sincronizando..." : "Sincronizar ahora")
                    .foregroundColor(isSyncing ? Color("AppTextSecondary") : (isAuthenticated ? Color("AppPrimary") : Color("AppTextSecondary")))
            }
        }
        .disabled(isSyncing || !isAuthenticated)
    }
}

private struct RetrySyncButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "arrow.clockwise.circle.fill")
                    .foregroundColor(.blue)
                Text("Reintentar sincronización")
                    .foregroundColor(.blue)
            }
        }
    }
}

private struct DatabaseResetButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Reparar base de datos")
                    .foregroundColor(.orange)
            }
        }
    }
}
