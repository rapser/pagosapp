import SwiftUI

/// Groups the lower-frequency Settings sections (Security, Legal, About, Data)
/// behind one row, decluttering the top-level Settings screen.
struct SettingsGeneralView: View {
    let onUnlinkDeviceTapped: () -> Void

    var body: some View {
        Form {
            SecuritySectionView()
            LegalSectionView()
            AboutSectionView()
            DataSectionView(onUnlinkDeviceTapped: onUnlinkDeviceTapped)
        }
        .navigationTitle(L10n.Settings.General.title)
    }
}
