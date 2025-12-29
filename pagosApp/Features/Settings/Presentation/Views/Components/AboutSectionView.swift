import SwiftUI

struct AboutSectionView: View {
    var body: some View {
        Section(header: Text("Acerca de").foregroundColor(Color("AppTextPrimary"))) {
            HStack {
                Text("Versión")
                    .foregroundColor(Color("AppTextPrimary"))
                Spacer()
                Text("1.0.0")
                    .foregroundColor(Color("AppTextSecondary"))
            }
        }
    }
}
