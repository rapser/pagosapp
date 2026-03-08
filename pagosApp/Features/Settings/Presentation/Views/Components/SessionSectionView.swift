import SwiftUI

struct SessionSectionView: View {
    let onLogoutTapped: () -> Void

    var body: some View {
        Section {
            Button {
                onLogoutTapped()
            } label: {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .foregroundColor(Color("AppPrimary"))
                    Text(L10n.Settings.Logout.button)
                        .foregroundColor(Color("AppTextPrimary"))
                }
            }
        }
    }
}
