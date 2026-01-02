//
//  GetLocalProfileUseCase.swift
//  pagosApp
//
//  Use Case: Get user profile from local storage
//  Clean Architecture: Business logic in Domain layer
//

import Foundation
import OSLog

/// Get user profile from local storage (offline-first)
final class GetLocalProfileUseCase {
    private let userProfileRepository: UserProfileRepositoryProtocol
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "GetLocalProfileUseCase")

    init(userProfileRepository: UserProfileRepositoryProtocol) {
        self.userProfileRepository = userProfileRepository
    }

    /// Execute: Get profile from local storage
    /// - Returns: Result with optional UserProfileEntity or UserProfileError
    func execute() async -> Result<UserProfileEntity?, UserProfileError> {
        logger.debug("📱 Fetching profile from local storage")

        let result = await userProfileRepository.getLocalProfile()

        if case .success(let profile) = result {
            if profile != nil {
                logger.info("✅ Profile loaded from local storage")
            } else {
                logger.info("ℹ️ No local profile found")
            }
        } else if case .failure(let error) = result {
            logger.error("❌ Failed to load local profile: \(error.errorCode)")
        }

        return result
    }
}
