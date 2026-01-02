import SwiftUI

struct AboutSectionView: View {
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        Section(header: Text("Acerca de").foregroundColor(Color("AppTextPrimary"))) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(Color("AppPrimary"))
                Text("Versión")
                    .foregroundColor(Color("AppTextPrimary"))
                Spacer()
                Text("\(appVersion) (\(buildNumber))")
                    .foregroundColor(Color("AppTextSecondary"))
            }

            HStack {
                Image(systemName: "apple.logo")
                    .foregroundColor(Color("AppPrimary"))
                Text("Desarrollado por")
                    .foregroundColor(Color("AppTextPrimary"))
                Spacer()
                Text("PagosApp Team")
                    .foregroundColor(Color("AppTextSecondary"))
            }
        }
    }
}
