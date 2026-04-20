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
    private let log: DomainLogWriter

    // Lazy-loaded data sources
    private lazy var remoteDataSource: UserProfileRemoteDataSource = {
        UserProfileSupabaseDataSource(client: supabaseClient)
    }()

    private lazy var localDataSource: UserProfileLocalDataSource = {
        UserProfileSwiftDataDataSource(modelContext: modelContext)
    }()

    // Mappers
    private let domainMapper: UserProfileDomainMapping = UserProfileDomainMapper()
    private let remoteDTOMapper: UserProfileRemoteDTOMapping = UserProfileRemoteDTOMapper()
    private let uiMapper: UserProfileUIMapping = UserProfileUIMapper()

    // MARK: - Initialization

    init(supabaseClient: SupabaseClient, modelContext: ModelContext, log: DomainLogWriter) {
        self.supabaseClient = supabaseClient
        self.modelContext = modelContext
        self.log = log
    }

    // MARK: - Repository

    func makeUserProfileRepository() -> UserProfileRepositoryProtocol {
        return UserProfileRepositoryImpl(
            remoteDataSource: remoteDataSource,
            localDataSource: localDataSource,
            domainMapper: domainMapper,
            remoteDTOMapper: remoteDTOMapper
        )
    }

    // MARK: - Use Cases

    func makeFetchUserProfileUseCase() -> FetchUserProfileUseCase {
        return FetchUserProfileUseCase(
            userProfileRepository: makeUserProfileRepository(),
            log: log
        )
    }

    func makeGetLocalProfileUseCase() -> GetLocalProfileUseCase {
        return GetLocalProfileUseCase(
            userProfileRepository: makeUserProfileRepository(),
            log: log
        )
    }

    func makeUpdateUserProfileUseCase() -> UpdateUserProfileUseCase {
        return UpdateUserProfileUseCase(
            userProfileRepository: makeUserProfileRepository(),
            log: log
        )
    }

    func makeDeleteLocalProfileUseCase() -> DeleteLocalProfileUseCase {
        return DeleteLocalProfileUseCase(
            userProfileRepository: makeUserProfileRepository(),
            log: log
        )
    }

    // MARK: - ViewModels

    func makeUserProfileViewModel() -> UserProfileViewModel {
        return UserProfileViewModel(
            fetchUserProfileUseCase: makeFetchUserProfileUseCase(),
            getLocalProfileUseCase: makeGetLocalProfileUseCase(),
            updateUserProfileUseCase: makeUpdateUserProfileUseCase(),
            deleteLocalProfileUseCase: makeDeleteLocalProfileUseCase(),
            mapper: uiMapper
        )
    }
}
