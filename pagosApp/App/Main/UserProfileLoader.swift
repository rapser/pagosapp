import SwiftUI

/// Listens for UserDidLogin notification and fetches user profile
struct UserProfileLoader: ViewModifier {
    @Environment(AppDependencies.self) private var dependencies

    private static let logCategory = "UserProfileLoader"

    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UserDidLogin"))) { notification in
                // Fetch user profile when user logs in (respects Clean Architecture - no direct coupling)
                Task {
                    let log = dependencies.domainLog
                    // Extract userId from notification
                    guard let userInfo = notification.userInfo,
                          let userId = userInfo["userId"] as? UUID else {
                        log.warning(
                            "⚠️ UserDidLogin notification received but no userId found",
                            category: Self.logCategory
                        )
                        return
                    }

                    log.info("📥 Fetching user profile for userId: \(userId.uuidString)", category: Self.logCategory)
                    let fetchProfileUseCase = dependencies.userProfileDependencyContainer.makeFetchUserProfileUseCase()
                    let result = await fetchProfileUseCase.execute(userId: userId)

                    if case .success = result {
                        log.info("✅ User profile fetched and saved during login", category: Self.logCategory)
                    } else {
                        log.error("❌ Failed to fetch user profile during login", category: Self.logCategory)
                    }
                }
            }
    }
}

extension View {
    func loadUserProfileOnLogin() -> some View {
        modifier(UserProfileLoader())
    }
}
