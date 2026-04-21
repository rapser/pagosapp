//
//  GetLocalProfileUseCase.swift
//  pagosApp
//
//  Use Case: Get user profile from local storage
//  Clean Architecture: Business logic in Domain layer
//

import Foundation

/// Get user profile from local storage (offline-first)
final class GetLocalProfileUseCase {
    private static let logCategory = "GetLocalProfileUseCase"

    private let userProfileRepository: UserProfileRepositoryProtocol
    private let log: DomainLogWriter

    init(userProfileRepository: UserProfileRepositoryProtocol, log: DomainLogWriter) {
        self.userProfileRepository = userProfileRepository
        self.log = log
    }

    /// Execute: Get profile from local storage
    /// - Returns: Result with optional UserProfile or UserProfileError
    func execute() async -> Result<UserProfile?, UserProfileError> {
        log.debug("📱 Fetching profile from local storage", category: Self.logCategory)

        let result = await userProfileRepository.getLocalProfile()

        if case .success(let profile) = result {
            if profile != nil {
                log.info("✅ Profile loaded from local storage", category: Self.logCategory)
            } else {
                log.info("ℹ️ No local profile found", category: Self.logCategory)
            }
        } else if case .failure(let error) = result {
            log.error("❌ Failed to load local profile: \(error.errorCode)", category: Self.logCategory)
        }

        return result
    }
}
