import SwiftUI

struct SessionSectionView: View {
    let onLogoutTapped: () -> Void
    let onUnlinkDeviceTapped: () -> Void

    var body: some View {
        Section(header: Text("Sesión").foregroundColor(Color("AppTextPrimary"))) {
            Button("Cerrar Sesión") {
                onLogoutTapped()
            }
            .foregroundColor(Color("AppTextPrimary"))

            Button("Desvincular Dispositivo", role: .destructive) {
                onUnlinkDeviceTapped()
            }
        }
    }
}
