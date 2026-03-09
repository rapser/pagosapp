import SwiftUI

struct AboutSectionView: View {
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        Section(header: Text(L10n.Settings.sectionAbout).foregroundColor(Color("AppTextPrimary"))) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(Color("AppPrimary"))
                Text(L10n.Settings.aboutVersion)
                    .foregroundColor(Color("AppTextPrimary"))
                Spacer()
                Text("\(appVersion) (\(buildNumber))")
                    .foregroundColor(Color("AppTextSecondary"))
            }

            HStack {
                Image(systemName: "apple.logo")
                    .foregroundColor(Color("AppPrimary"))
                Text(L10n.Settings.aboutDevelopedBy)
                    .foregroundColor(Color("AppTextPrimary"))
                Spacer()
                Text(L10n.Settings.aboutTeam)
                    .foregroundColor(Color("AppTextSecondary"))
            }
        }
    }
}
