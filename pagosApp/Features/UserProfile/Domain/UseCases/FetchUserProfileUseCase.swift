//
//  FetchUserProfileUseCase.swift
//  pagosApp
//
//  Use Case: Fetch user profile from remote and save locally
//  Clean Architecture: Business logic in Domain layer
//

import Foundation

/// Fetch user profile from Supabase and save to local storage
@MainActor
final class FetchUserProfileUseCase {
    private static let logCategory = "FetchUserProfileUseCase"

    private let userProfileRepository: UserProfileRepositoryProtocol
    private let log: DomainLogWriter

    init(userProfileRepository: UserProfileRepositoryProtocol, log: DomainLogWriter) {
        self.userProfileRepository = userProfileRepository
        self.log = log
    }

    /// Execute: Fetch profile from remote and save locally
    /// - Parameter userId: User ID to fetch profile for
    /// - Returns: Result with UserProfile or UserProfileError
    func execute(userId: UUID) async -> Result<UserProfile, UserProfileError> {
        log.info("📥 Fetching profile for user: \(userId)", category: Self.logCategory)

        // 1. Fetch from remote
        let fetchResult = await userProfileRepository.fetchProfile(userId: userId)

        guard case .success(let profile) = fetchResult else {
            log.error("❌ Failed to fetch profile from remote", category: Self.logCategory)
            return fetchResult
        }

        log.info("✅ Profile fetched from remote", category: Self.logCategory)

        // 2. Save to local storage
        let saveResult = await userProfileRepository.saveLocalProfile(profile)

        if case .failure(let error) = saveResult {
            log.warning("⚠️ Profile fetched but failed to save locally: \(error.errorCode)", category: Self.logCategory)
            // Still return success since remote fetch succeeded
        } else {
            log.info("✅ Profile saved to local storage", category: Self.logCategory)
        }

        return .success(profile)
    }
}
