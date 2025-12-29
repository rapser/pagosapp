import SwiftUI
import SwiftData
import Supabase

struct ProfileSectionView: View {
    @Environment(AuthenticationManager.self) private var authManager
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Section(header: Text("Perfil").foregroundColor(Color("AppTextPrimary"))) {
            if (authManager.isAuthenticated || authManager.isSessionActive),
               let client = authManager.supabaseClient {
                NavigationLink(destination: UserProfileView()) {
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
