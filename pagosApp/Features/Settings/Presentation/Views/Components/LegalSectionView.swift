import SwiftUI

struct LegalSectionView: View {
    var body: some View {
        Section(header: Text("Legal").foregroundColor(Color("AppTextPrimary"))) {
            Link(destination: URL(string: "https://www.apple.com/legal/privacy")!) {
                HStack {
                    Image(systemName: "hand.raised.fill")
                        .foregroundColor(Color("AppPrimary"))
                    Text("Política de Privacidad")
                        .foregroundColor(Color("AppTextPrimary"))
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundColor(Color("AppTextSecondary"))
                }
            }

            Link(destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!) {
                HStack {
                    Image(systemName: "doc.text.fill")
                        .foregroundColor(Color("AppPrimary"))
                    Text("Términos y Condiciones")
                        .foregroundColor(Color("AppTextPrimary"))
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundColor(Color("AppTextSecondary"))
                }
            }

            Link(destination: URL(string: "https://www.apple.com/legal/privacy/")!) {
                HStack {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundColor(Color("AppPrimary"))
                    Text("Licencias de Código Abierto")
                        .foregroundColor(Color("AppTextPrimary"))
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundColor(Color("AppTextSecondary"))
                }
            }
        }
    }
}
