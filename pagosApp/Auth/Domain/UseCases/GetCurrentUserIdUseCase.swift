//
//  GetCurrentUserIdUseCase.swift
//  pagosApp
//
//  Use Case to get current authenticated user ID
//  Clean Architecture - Domain Layer
//

import Foundation

/// Use Case to retrieve the current authenticated user's ID
final class GetCurrentUserIdUseCase {
    private let authRepository: AuthRepositoryProtocol

    init(authRepository: AuthRepositoryProtocol) {
        self.authRepository = authRepository
    }

    /// Execute: Get current user ID if authenticated
    /// - Returns: User ID as UUID, or nil if not authenticated
    func execute() async -> UUID? {
        return await authRepository.getCurrentUserId()
    }
}
