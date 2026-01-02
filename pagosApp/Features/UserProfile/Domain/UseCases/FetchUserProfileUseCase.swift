//
//  FetchUserProfileUseCase.swift
//  pagosApp
//
//  Use Case: Fetch user profile from remote and save locally
//  Clean Architecture: Business logic in Domain layer
//

import Foundation
import OSLog

/// Fetch user profile from Supabase and save to local storage
final class FetchUserProfileUseCase {
    private let userProfileRepository: UserProfileRepositoryProtocol
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "FetchUserProfileUseCase")

    init(userProfileRepository: UserProfileRepositoryProtocol) {
        self.userProfileRepository = userProfileRepository
    }

    /// Execute: Fetch profile from remote and save locally
    /// - Parameter userId: User ID to fetch profile for
    /// - Returns: Result with UserProfileEntity or UserProfileError
    func execute(userId: UUID) async -> Result<UserProfileEntity, UserProfileError> {
        logger.info("📥 Fetching profile for user: \(userId)")

        // 1. Fetch from remote
        let fetchResult = await userProfileRepository.fetchProfile(userId: userId)

        guard case .success(let profile) = fetchResult else {
            logger.error("❌ Failed to fetch profile from remote")
            return fetchResult
        }

        logger.info("✅ Profile fetched from remote")

        // 2. Save to local storage
        let saveResult = await userProfileRepository.saveLocalProfile(profile)

        if case .failure(let error) = saveResult {
            logger.warning("⚠️ Profile fetched but failed to save locally: \(error.errorCode)")
            // Still return success since remote fetch succeeded
        } else {
            logger.info("✅ Profile saved to local storage")
        }

        return .success(profile)
    }
}
