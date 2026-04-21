//
//  UserProfileRepositoryImpl.swift
//  pagosApp
//
//  Repository implementation using DataSources and Mappers
//  Clean Architecture: Data layer - Repository implementation
//

import Foundation
import SwiftData

/// Repository implementation for UserProfile
@MainActor
final class UserProfileRepositoryImpl: UserProfileRepositoryProtocol {
    private static let logCategory = "UserProfileRepositoryImpl"

    private let remoteDataSource: UserProfileRemoteDataSource
    private let localDataSource: UserProfileLocalDataSource
    private let domainMapper: UserProfileDomainMapping
    private let remoteDTOMapper: UserProfileRemoteDTOMapping
    private let log: DomainLogWriter

    init(
        remoteDataSource: UserProfileRemoteDataSource,
        localDataSource: UserProfileLocalDataSource,
        domainMapper: UserProfileDomainMapping,
        remoteDTOMapper: UserProfileRemoteDTOMapping,
        log: DomainLogWriter
    ) {
        self.remoteDataSource = remoteDataSource
        self.localDataSource = localDataSource
        self.domainMapper = domainMapper
        self.remoteDTOMapper = remoteDTOMapper
        self.log = log
    }

    func fetchProfile(userId: UUID) async -> Result<UserProfile, UserProfileError> {
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

    func updateProfile(_ profile: UserProfile) async -> Result<UserProfile, UserProfileError> {
        do {
            let profileDTO = remoteDTOMapper.toRemoteDTO(profile)
            try await remoteDataSource.updateProfile(profileDTO)
            return .success(profile)
        } catch {
            log.error(L10n.Log.Profile.updateFailed(error.localizedDescription), category: Self.logCategory)
            return .failure(.updateFailed(error.localizedDescription))
        }
    }

    // MARK: - Local Operations

    func getLocalProfile() async -> Result<UserProfile?, UserProfileError> {
        return await _getLocalProfile()
    }

    func saveLocalProfile(_ profile: UserProfile) async -> Result<Void, UserProfileError> {
        let result = await _saveLocalProfile(profile)
        if case .success = result {
            NotificationCenter.default.post(name: NSNotification.Name("UserProfileDidUpdate"), object: nil)
        }
        return result
    }

    func deleteLocalProfile() async -> Result<Void, UserProfileError> {
        return await _deleteLocalProfile()
    }

    // MARK: - Private @MainActor methods for SwiftData operations

    private func _getLocalProfile() async -> Result<UserProfile?, UserProfileError> {
        do {
            let profileDTOs = try await localDataSource.fetchAll()
            let profileDomain = profileDTOs.first.map { domainMapper.toDomain($0) }
            return .success(profileDomain)

        } catch {
            log.error(L10n.Log.Profile.fetchLocalFailed(error.localizedDescription), category: Self.logCategory)
            return .failure(.fetchFailed(error.localizedDescription))
        }
    }

    private func _saveLocalProfile(_ profile: UserProfile) async -> Result<Void, UserProfileError> {
        do {
            // Delete existing profiles (single profile per user)
            let existingProfiles = try await localDataSource.fetchAll()
            if !existingProfiles.isEmpty {
                try await localDataSource.deleteAll(existingProfiles)
            }

            // Convert Domain -> LocalDTO and save
            let profileDTO = domainMapper.toLocalDTO(profile)
            try await localDataSource.save(profileDTO)
            return .success(())

        } catch {
            log.error(L10n.Log.Profile.saveLocalFailed(error.localizedDescription), category: Self.logCategory)
            return .failure(.saveFailed(error.localizedDescription))
        }
    }

    private func _deleteLocalProfile() async -> Result<Void, UserProfileError> {
        do {
            try await localDataSource.clear()
            return .success(())

        } catch {
            log.error(L10n.Log.Profile.deleteLocalFailed(error.localizedDescription), category: Self.logCategory)
            return .failure(.deleteFailed(error.localizedDescription))
        }
    }
}
