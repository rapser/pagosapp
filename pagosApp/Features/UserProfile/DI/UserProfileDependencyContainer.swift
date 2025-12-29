//
//  UserProfileDependencyContainer.swift
//  pagosApp
//
//  Dependency Injection Container for UserProfile module
//  Clean Architecture - DI Layer
//

import Foundation
import SwiftData
import Supabase

/// Dependency Injection container for UserProfile feature
@MainActor
final class UserProfileDependencyContainer {
    private let supabaseClient: SupabaseClient
    private let modelContext: ModelContext

    // Lazy-loaded data sources
    private lazy var remoteDataSource: UserProfileRemoteDataSource = {
        UserProfileSupabaseDataSource(client: supabaseClient)
    }()

    private lazy var localDataSource: UserProfileLocalDataSource = {
        UserProfileSwiftDataDataSource(modelContext: modelContext)
    }()

    // MARK: - Initialization

    init(supabaseClient: SupabaseClient, modelContext: ModelContext) {
        self.supabaseClient = supabaseClient
        self.modelContext = modelContext
    }

    // MARK: - Repository

    func makeUserProfileRepository() -> UserProfileRepositoryProtocol {
        return UserProfileRepositoryImpl(
            remoteDataSource: remoteDataSource,
            localDataSource: localDataSource
        )
    }

    // MARK: - Use Cases

    func makeFetchUserProfileUseCase() -> FetchUserProfileUseCase {
        return FetchUserProfileUseCase(
            userProfileRepository: makeUserProfileRepository()
        )
    }

    func makeGetLocalProfileUseCase() -> GetLocalProfileUseCase {
        return GetLocalProfileUseCase(
            userProfileRepository: makeUserProfileRepository()
        )
    }

    func makeUpdateUserProfileUseCase() -> UpdateUserProfileUseCase {
        return UpdateUserProfileUseCase(
            userProfileRepository: makeUserProfileRepository()
        )
    }

    func makeDeleteLocalProfileUseCase() -> DeleteLocalProfileUseCase {
        return DeleteLocalProfileUseCase(
            userProfileRepository: makeUserProfileRepository()
        )
    }

    // MARK: - ViewModels

    func makeUserProfileViewModel() -> UserProfileViewModel {
        return UserProfileViewModel(
            fetchUserProfileUseCase: makeFetchUserProfileUseCase(),
            getLocalProfileUseCase: makeGetLocalProfileUseCase(),
            updateUserProfileUseCase: makeUpdateUserProfileUseCase(),
            deleteLocalProfileUseCase: makeDeleteLocalProfileUseCase()
        )
    }
}
