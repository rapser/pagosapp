import SwiftUI

struct SecuritySectionView: View {
    @Environment(AuthenticationManager.self) private var authManager

    var body: some View {
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
    }
}
