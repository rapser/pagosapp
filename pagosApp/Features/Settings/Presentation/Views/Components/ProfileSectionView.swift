import SwiftUI

struct ProfileSectionView: View {
    @Environment(SessionCoordinator.self) private var sessionCoordinator
    @Environment(AppDependencies.self) private var dependencies

    var body: some View {
        Section(header: Text(L10n.Settings.sectionProfile).foregroundColor(Color("AppTextPrimary"))) {
            if (sessionCoordinator.isAuthenticated || sessionCoordinator.isSessionActive) {
                NavigationLink(destination: UserProfileView(
                    viewModel: dependencies.userProfileDependencyContainer.makeUserProfileViewModel()
                )) {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .foregroundColor(Color("AppPrimary"))
                        Text(L10n.Settings.profileMyProfile)
                            .foregroundColor(Color("AppTextPrimary"))
                    }
                }
            } else {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(Color("AppTextSecondary"))
                    Text(L10n.Settings.profileMyProfile)
                        .foregroundColor(Color("AppTextSecondary"))
                    Spacer()
                    Text(L10n.Settings.profileSignIn)
                        .font(.caption)
                        .foregroundColor(Color("AppTextSecondary"))
                }
            }
        }
    }
}
