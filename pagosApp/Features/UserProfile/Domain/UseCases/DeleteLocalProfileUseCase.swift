//
//  DeleteLocalProfileUseCase.swift
//  pagosApp
//
//  Use Case: Delete user profile from local storage
//  Clean Architecture: Business logic in Domain layer
//

import Foundation

/// Delete user profile from local storage (called on logout)
@MainActor
final class DeleteLocalProfileUseCase {
    private static let logCategory = "DeleteLocalProfileUseCase"

    private let userProfileRepository: UserProfileRepositoryProtocol
    private let log: DomainLogWriter

    init(userProfileRepository: UserProfileRepositoryProtocol, log: DomainLogWriter) {
        self.userProfileRepository = userProfileRepository
        self.log = log
    }

    /// Execute: Delete profile from local storage
    /// - Returns: Result with Void or UserProfileError
    func execute() async -> Result<Void, UserProfileError> {
        log.info("🗑️ Deleting local profile", category: Self.logCategory)

        let result = await userProfileRepository.deleteLocalProfile()

        if case .success = result {
            log.info("✅ Local profile deleted successfully", category: Self.logCategory)
        } else if case .failure(let error) = result {
            log.error("❌ Failed to delete local profile: \(error.errorCode)", category: Self.logCategory)
        }

        return result
    }
}
