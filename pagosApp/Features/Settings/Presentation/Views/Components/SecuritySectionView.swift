import SwiftUI

struct SecuritySectionView: View {
    @Environment(SessionCoordinator.self) private var sessionCoordinator

    var body: some View {
        Section(header: Text("Seguridad").foregroundColor(Color("AppTextPrimary"))) {
            NavigationLink(destination: BiometricSettingsView().environment(sessionCoordinator)) {
                HStack {
                    Image(systemName: "faceid")
                        .foregroundColor(Color("AppPrimary"))
                    Text("Autenticación Biométrica")
                        .foregroundColor(Color("AppTextPrimary"))
                }
            }
        }
    }
}
