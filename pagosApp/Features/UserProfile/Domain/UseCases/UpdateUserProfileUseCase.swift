//
//  UpdateUserProfileUseCase.swift
//  pagosApp
//
//  Use Case: Update user profile in remote and local storage
//  Clean Architecture: Business logic in Domain layer
//

import Foundation
import OSLog

/// Update user profile in Supabase and local storage
final class UpdateUserProfileUseCase {
    private let userProfileRepository: UserProfileRepositoryProtocol
    private let validator: UserProfileValidator
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "UpdateUserProfileUseCase")

    init(userProfileRepository: UserProfileRepositoryProtocol, validator: UserProfileValidator = UserProfileValidator()) {
        self.userProfileRepository = userProfileRepository
        self.validator = validator
    }

    /// Execute: Update profile in remote and local
    /// - Parameter profile: Updated UserProfile
    /// - Returns: Result with updated UserProfile or UserProfileError
    func execute(_ profile: UserProfile) async -> Result<UserProfile, UserProfileError> {
        logger.info("📤 Updating profile for user: \(profile.userId)")

        // 1. Validate profile
        do {
            try validator.validate(profile)
        } catch let error as UserProfileError {
            logger.error("❌ Profile validation failed: \(error.errorCode)")
            return .failure(error)
        } catch {
            logger.error("❌ Profile validation failed: \(error.localizedDescription)")
            return .failure(.unknown(error.localizedDescription))
        }

        // 2. Update in remote
        let updateResult = await userProfileRepository.updateProfile(profile)

        guard case .success(let updatedProfile) = updateResult else {
            logger.error("❌ Failed to update profile in remote")
            return updateResult
        }

        logger.info("✅ Profile updated in remote")

        // 3. Save to local storage
        let saveResult = await userProfileRepository.saveLocalProfile(updatedProfile)

        if case .failure(let error) = saveResult {
            logger.warning("⚠️ Profile updated remotely but failed to save locally: \(error.errorCode)")
            // Still return success since remote update succeeded
        } else {
            logger.info("✅ Profile saved to local storage")
        }

        return .success(updatedProfile)
    }
}
