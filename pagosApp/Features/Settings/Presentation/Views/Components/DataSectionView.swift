import SwiftUI

struct DataSectionView: View {
    let onUnlinkDeviceTapped: () -> Void

    var body: some View {
        Section(
            header: Text(L10n.Settings.DataSection.sectionTitle).foregroundColor(Color("AppTextPrimary")),
            footer: Text(L10n.Settings.DataSection.footer)
                .font(.caption)
                .foregroundColor(Color("AppTextSecondary"))
        ) {
            Button(role: .destructive) {
                onUnlinkDeviceTapped()
            } label: {
                HStack {
                    Image(systemName: "trash.fill")
                    Text(L10n.Settings.DataSection.unlinkButton)
                }
            }
        }
    }
}
