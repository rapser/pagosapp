//
//  UserProfileRepositoryImpl.swift
//
//  Repository implementation using DataSources and Mappers
//

import Foundation
import SwiftData

/// Remote operations are `nonisolated`; SwiftData paths are `@MainActor` (Swift 6).
final class UserProfileRepositoryImpl: UserProfileRepositoryProtocol, @unchecked Sendable {
    private nonisolated static let logCategory = "UserProfileRepositoryImpl"

    private nonisolated let remoteDataSource: any UserProfileRemoteDataSource
    private nonisolated let remoteDTOMapper: any UserProfileRemoteDTOMapping
    private nonisolated let log: any DomainLogWriter
    private let localDataSource: any UserProfileLocalDataSource
    private let domainMapper: any UserProfileDomainMapping

    init(
        remoteDataSource: any UserProfileRemoteDataSource,
        localDataSource: any UserProfileLocalDataSource,
        domainMapper: any UserProfileDomainMapping,
        remoteDTOMapper: any UserProfileRemoteDTOMapping,
        log: any DomainLogWriter
    ) {
        self.remoteDataSource = remoteDataSource
        self.localDataSource = localDataSource
        self.domainMapper = domainMapper
        self.remoteDTOMapper = remoteDTOMapper
        self.log = log
    }

    nonisolated func fetchProfile(userId: UUID) async -> Result<UserProfile, UserProfileError> {
        do {
            guard let profileDTO = try await remoteDataSource.fetchProfile(userId: userId) else {
                return .failure(.profileNotFound)
            }
            let profileDomain = remoteDTOMapper.toDomain(profileDTO)
            return .success(profileDomain)
        } catch {
            log.error(L10n.Log.Profile.fetchFailed(error.localizedDescription), category: Self.logCategory)
            return .failure(.fetchFailed(error.localizedDescription))
        }
    }

    nonisolated func updateProfile(_ profile: UserProfile) async -> Result<UserProfile, UserProfileError> {
        do {
            let profileDTO = remoteDTOMapper.toRemoteDTO(profile)
            try await remoteDataSource.updateProfile(profileDTO)
            return .success(profile)
        } catch {
            log.error(L10n.Log.Profile.updateFailed(error.localizedDescription), category: Self.logCategory)
            return .failure(.updateFailed(error.localizedDescription))
        }
    }

    // MARK: - Local (SwiftData on main actor)

    @MainActor
    func getLocalProfile() async -> Result<UserProfile?, UserProfileError> {
        do {
            let profileDTOs = try await localDataSource.fetchAll()
            let profileDomain = profileDTOs.first.map { domainMapper.toDomain($0) }
            return .success(profileDomain)
        } catch {
            log.error(L10n.Log.Profile.fetchLocalFailed(error.localizedDescription), category: Self.logCategory)
            return .failure(.fetchFailed(error.localizedDescription))
        }
    }

    @MainActor
    func saveLocalProfile(_ profile: UserProfile) async -> Result<Void, UserProfileError> {
        do {
            let existingProfiles = try await localDataSource.fetchAll()
            if !existingProfiles.isEmpty {
                try await localDataSource.deleteAll(existingProfiles)
            }
            let profileDTO = domainMapper.toLocalDTO(profile)
            try await localDataSource.save(profileDTO)
            NotificationCenter.default.post(name: NSNotification.Name("UserProfileDidUpdate"), object: nil)
            return .success(())
        } catch {
            log.error(L10n.Log.Profile.saveLocalFailed(error.localizedDescription), category: Self.logCategory)
            return .failure(.saveFailed(error.localizedDescription))
        }
    }

    @MainActor
    func deleteLocalProfile() async -> Result<Void, UserProfileError> {
        do {
            try await localDataSource.clear()
            return .success(())
        } catch {
            log.error(L10n.Log.Profile.deleteLocalFailed(error.localizedDescription), category: Self.logCategory)
            return .failure(.deleteFailed(error.localizedDescription))
        }
    }
}
