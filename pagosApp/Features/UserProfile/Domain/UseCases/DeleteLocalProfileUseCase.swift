//
//  DeleteLocalProfileUseCase.swift
//  pagosApp
//
//  Use Case: Delete user profile from local storage
//  Clean Architecture: Business logic in Domain layer
//

import Foundation
import OSLog

/// Delete user profile from local storage (called on logout)
final class DeleteLocalProfileUseCase {
    private let userProfileRepository: UserProfileRepositoryProtocol
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "DeleteLocalProfileUseCase")

    init(userProfileRepository: UserProfileRepositoryProtocol) {
        self.userProfileRepository = userProfileRepository
    }

    /// Execute: Delete profile from local storage
    /// - Returns: Result with Void or UserProfileError
    func execute() async -> Result<Void, UserProfileError> {
        logger.info("🗑️ Deleting local profile")

        let result = await userProfileRepository.deleteLocalProfile()

        if case .success = result {
            logger.info("✅ Local profile deleted successfully")
        } else if case .failure(let error) = result {
            logger.error("❌ Failed to delete local profile: \(error.errorCode)")
        }

        return result
    }
}
