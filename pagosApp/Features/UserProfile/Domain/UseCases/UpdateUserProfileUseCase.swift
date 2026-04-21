//
//  UpdateUserProfileUseCase.swift
//  pagosApp
//
//  Use Case: Update user profile in remote and local storage
//  Clean Architecture: Business logic in Domain layer
//

import Foundation

/// Update user profile in Supabase and local storage
final class UpdateUserProfileUseCase {
    private static let logCategory = "UpdateUserProfileUseCase"

    private let userProfileRepository: UserProfileRepositoryProtocol
    private let validator: UserProfileValidator
    private let log: DomainLogWriter

    init(
        userProfileRepository: UserProfileRepositoryProtocol,
        log: DomainLogWriter,
        validator: UserProfileValidator = UserProfileValidator()
    ) {
        self.userProfileRepository = userProfileRepository
        self.log = log
        self.validator = validator
    }

    /// Execute: Update profile in remote and local
    /// - Parameter profile: Updated UserProfile
    /// - Returns: Result with updated UserProfile or UserProfileError
    func execute(_ profile: UserProfile) async -> Result<UserProfile, UserProfileError> {
        log.info("📤 Updating profile for user: \(profile.userId)", category: Self.logCategory)

        // 1. Validate profile
        do {
            try validator.validate(profile)
        } catch let error as UserProfileError {
            log.error("❌ Profile validation failed: \(error.errorCode)", category: Self.logCategory)
            return .failure(error)
        } catch {
            log.error("❌ Profile validation failed: \(error.localizedDescription)", category: Self.logCategory)
            return .failure(.unknown(error.localizedDescription))
        }

        // 2. Update in remote
        let updateResult = await userProfileRepository.updateProfile(profile)

        guard case .success(let updatedProfile) = updateResult else {
            log.error("❌ Failed to update profile in remote", category: Self.logCategory)
            return updateResult
        }

        log.info("✅ Profile updated in remote", category: Self.logCategory)

        // 3. Save to local storage
        let saveResult = await userProfileRepository.saveLocalProfile(updatedProfile)

        if case .failure(let error) = saveResult {
            log.warning("⚠️ Profile updated remotely but failed to save locally: \(error.errorCode)", category: Self.logCategory)
            // Still return success since remote update succeeded
        } else {
            log.info("✅ Profile saved to local storage", category: Self.logCategory)
        }

        return .success(updatedProfile)
    }
}
