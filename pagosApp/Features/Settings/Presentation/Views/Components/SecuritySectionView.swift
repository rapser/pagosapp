import SwiftUI

struct SecuritySectionView: View {
    @Environment(SessionCoordinator.self) private var sessionCoordinator

    var body: some View {
        Section(header: Text(L10n.Settings.Biometric.title).foregroundColor(Color("AppTextPrimary"))) {
            NavigationLink(destination: BiometricSettingsView().environment(sessionCoordinator)) {
                HStack {
                    Image(systemName: "faceid")
                        .foregroundColor(Color("AppPrimary"))
                    Text(L10n.Settings.Biometric.fastAccess)
                        .foregroundColor(Color("AppTextPrimary"))
                }
            }
        }
    }
}
