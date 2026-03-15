import SwiftUI

struct LegalSectionView: View {
    var body: some View {
        Section(header: Text(L10n.Settings.sectionLegal).foregroundColor(Color("AppTextPrimary"))) {
            Link(destination: URL(string: "https://www.apple.com/legal/privacy")!) {
                HStack {
                    Image(systemName: "hand.raised.fill")
                        .foregroundColor(Color("AppPrimary"))
                    Text(L10n.Settings.legalPrivacy)
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
                    Text(L10n.Settings.legalTerms)
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
                    Text(L10n.Settings.legalLicenses)
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
