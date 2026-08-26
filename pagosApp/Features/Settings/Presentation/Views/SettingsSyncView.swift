import SwiftUI

/// Groups the sync status and actions behind one row, decluttering the top-level Settings screen.
struct SettingsSyncView: View {
    let onSyncTapped: () -> Void
    let onRetrySyncTapped: () -> Void
    let onDatabaseResetTapped: () -> Void

    var body: some View {
        Form {
            SyncSectionView(
                onSyncTapped: onSyncTapped,
                onRetrySyncTapped: onRetrySyncTapped,
                onDatabaseResetTapped: onDatabaseResetTapped
            )
        }
        .navigationTitle(L10n.Settings.sectionSync)
    }
}
