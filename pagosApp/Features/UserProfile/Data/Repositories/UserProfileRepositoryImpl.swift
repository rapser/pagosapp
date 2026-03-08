//
//  UserProfileRepositoryImpl.swift
//  pagosApp
//
//  Repository implementation using DataSources and Mappers
//  Clean Architecture: Data layer - Repository implementation
//

import Foundation
import SwiftData
import OSLog

/// Repository implementation for UserProfile
@MainActor
final class UserProfileRepositoryImpl: UserProfileRepositoryProtocol {
    private let remoteDataSource: UserProfileRemoteDataSource
    private let localDataSource: UserProfileLocalDataSource
    private let domainMapper: UserProfileDomainMapping
    private let remoteDTOMapper: UserProfileRemoteDTOMapping
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "UserProfileRepositoryImpl")

    init(
        remoteDataSource: UserProfileRemoteDataSource,
        localDataSource: UserProfileLocalDataSource,
        domainMapper: UserProfileDomainMapping,
        remoteDTOMapper: UserProfileRemoteDTOMapping
    ) {
        self.remoteDataSource = remoteDataSource
        self.localDataSource = localDataSource
        self.domainMapper = domainMapper
        self.remoteDTOMapper = remoteDTOMapper
        logger.info("\(L10n.Log.Profile.initRepo)")
    }

    // MARK: - Remote Operations

    func fetchProfile(userId: UUID) async -> Result<UserProfile, UserProfileError> {
        logger.info("\(L10n.Log.Profile.fetching(userId.uuidString))")

        do {
            guard let profileDTO = try await remoteDataSource.fetchProfile(userId: userId) else {
                logger.error("\(L10n.Log.Profile.notFound(userId.uuidString))")
                return .failure(.profileNotFound)
            }

            let profileDomain = remoteDTOMapper.toDomain(profileDTO)
            logger.info("\(L10n.Log.Profile.fetchedMapped)")
            return .success(profileDomain)

        } catch {
            logger.error("\(L10n.Log.Profile.fetchFailed(error.localizedDescription))")
            return .failure(.fetchFailed(error.localizedDescription))
        }
    }

    func updateProfile(_ profile: UserProfile) async -> Result<UserProfile, UserProfileError> {
        logger.info("\(L10n.Log.Profile.updating(profile.userId.uuidString))")

        do {
            let profileDTO = remoteDTOMapper.toRemoteDTO(profile)
            try await remoteDataSource.updateProfile(profileDTO)

            logger.info("\(L10n.Log.Profile.updated)")
            return .success(profile)

        } catch {
            logger.error("\(L10n.Log.Profile.updateFailed(error.localizedDescription))")
            return .failure(.updateFailed(error.localizedDescription))
        }
    }

    // MARK: - Local Operations

    func getLocalProfile() async -> Result<UserProfile?, UserProfileError> {
        logger.debug("\(L10n.Log.Profile.fetchingLocal)")
        return await _getLocalProfile()
    }

    func saveLocalProfile(_ profile: UserProfile) async -> Result<Void, UserProfileError> {
        logger.debug("\(L10n.Log.Profile.savingLocal)")
        let result = await _saveLocalProfile(profile)

        // Notify that profile was saved
        if case .success = result {
            NotificationCenter.default.post(name: NSNotification.Name("UserProfileDidUpdate"), object: nil)
            logger.debug("\(L10n.Log.Profile.postedNotification)")
        }

        return result
    }

    func deleteLocalProfile() async -> Result<Void, UserProfileError> {
        logger.info("\(L10n.Log.Profile.deletingLocal)")
        return await _deleteLocalProfile()
    }

    // MARK: - Private @MainActor methods for SwiftData operations

    private func _getLocalProfile() async -> Result<UserProfile?, UserProfileError> {
        do {
            let profileDTOs = try await localDataSource.fetchAll()
            let profileDomain = profileDTOs.first.map { domainMapper.toDomain($0) }

            if profileDomain != nil {
                logger.debug("\(L10n.Log.Profile.localFound)")
            } else {
                logger.debug("\(L10n.Log.Profile.noLocalFound)")
            }

            return .success(profileDomain)

        } catch {
            logger.error("\(L10n.Log.Profile.fetchLocalFailed(error.localizedDescription))")
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

            logger.info("\(L10n.Log.Profile.savedToStorage)")
            return .success(())

        } catch {
            logger.error("\(L10n.Log.Profile.saveLocalFailed(error.localizedDescription))")
            return .failure(.saveFailed(error.localizedDescription))
        }
    }

    private func _deleteLocalProfile() async -> Result<Void, UserProfileError> {
        do {
            try await localDataSource.clear()
            logger.info("\(L10n.Log.Profile.localDeleted)")
            return .success(())

        } catch {
            logger.error("\(L10n.Log.Profile.deleteLocalFailed(error.localizedDescription))")
            return .failure(.deleteFailed(error.localizedDescription))
        }
    }
}
