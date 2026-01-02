import SwiftUI

struct DataSectionView: View {
    let onUnlinkDeviceTapped: () -> Void

    var body: some View {
        Section(
            header: Text("Datos del Dispositivo").foregroundColor(Color("AppTextPrimary")),
            footer: Text("Desvincular eliminará TODOS los datos locales de este dispositivo de forma permanente. Tus datos en la nube están seguros.")
                .font(.caption)
                .foregroundColor(Color("AppTextSecondary"))
        ) {
            Button(role: .destructive) {
                onUnlinkDeviceTapped()
            } label: {
                HStack {
                    Image(systemName: "trash.fill")
                    Text("Desvincular Dispositivo")
                }
            }
        }
    }
}
