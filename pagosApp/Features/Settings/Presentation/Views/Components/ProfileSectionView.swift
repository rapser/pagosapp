import SwiftUI

struct ProfileSectionView: View {
    @Environment(SessionCoordinator.self) private var sessionCoordinator
    @Environment(AppDependencies.self) private var dependencies

    var body: some View {
        Section(header: Text("Perfil").foregroundColor(Color("AppTextPrimary"))) {
            if (sessionCoordinator.isAuthenticated || sessionCoordinator.isSessionActive) {
                NavigationLink(destination: UserProfileView(
                    viewModel: dependencies.userProfileDependencyContainer.makeUserProfileViewModel()
                )) {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .foregroundColor(Color("AppPrimary"))
                        Text("Mi Perfil")
                            .foregroundColor(Color("AppTextPrimary"))
                    }
                }
            } else {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(Color("AppTextSecondary"))
                    Text("Mi Perfil")
                        .foregroundColor(Color("AppTextSecondary"))
                    Spacer()
                    Text("Inicia sesión")
                        .font(.caption)
                        .foregroundColor(Color("AppTextSecondary"))
                }
            }
        }
    }
}
