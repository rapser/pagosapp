import SwiftUI

struct SyncSectionView: View {
    @Environment(SessionCoordinator.self) private var sessionCoordinator
    @Environment(PaymentSyncCoordinator.self) private var syncManager

    let onSyncTapped: () -> Void
    let onRetrySyncTapped: () -> Void
    let onDatabaseResetTapped: () -> Void

    var body: some View {
        Section(header: Text(L10n.Settings.sectionSync).foregroundColor(Color("AppTextPrimary"))) {
            PendingSyncCountRow(pendingSyncCount: syncManager.pendingSyncCount)

            if let lastSync = syncManager.lastSyncDate {
                LastSyncDateRow(lastSyncDate: lastSync)
            }

            if !sessionCoordinator.isAuthenticated && !sessionCoordinator.isSessionActive {
                AuthenticationRequiredRow()
            }

            SyncButton(
                isSyncing: syncManager.isSyncing,
                isAuthenticated: sessionCoordinator.isAuthenticated || sessionCoordinator.isSessionActive,
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
            Text(L10n.Settings.syncPendingCount)
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
                Text(L10n.Settings.syncAllSynced)
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
            Text(L10n.Settings.syncLastSync)
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
            Text(L10n.Settings.syncSignInToSync)
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
                Text(isSyncing ? L10n.Payments.List.syncing : L10n.Settings.syncNow)
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
                Text(L10n.Settings.syncRetry)
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
                Text(L10n.Settings.syncRepairDb)
                    .foregroundColor(.orange)
            }
        }
    }
}
