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
        logger.info("✅ UserProfileRepositoryImpl initialized")
    }

    // MARK: - Remote Operations

    func fetchProfile(userId: UUID) async -> Result<UserProfile, UserProfileError> {
        logger.info("📥 Fetching profile for user: \(userId)")

        do {
            guard let profileDTO = try await remoteDataSource.fetchProfile(userId: userId) else {
                logger.error("❌ Profile not found for user: \(userId)")
                return .failure(.profileNotFound)
            }

            let profileDomain = remoteDTOMapper.toDomain(profileDTO)
            logger.info("✅ Profile fetched and mapped to domain entity")
            return .success(profileDomain)

        } catch {
            logger.error("❌ Failed to fetch profile: \(error.localizedDescription)")
            return .failure(.fetchFailed(error.localizedDescription))
        }
    }

    func updateProfile(_ profile: UserProfile) async -> Result<UserProfile, UserProfileError> {
        logger.info("📤 Updating profile for user: \(profile.userId)")

        do {
            let profileDTO = remoteDTOMapper.toRemoteDTO(profile)
            try await remoteDataSource.updateProfile(profileDTO)

            logger.info("✅ Profile updated successfully")
            return .success(profile)

        } catch {
            logger.error("❌ Failed to update profile: \(error.localizedDescription)")
            return .failure(.updateFailed(error.localizedDescription))
        }
    }

    // MARK: - Local Operations

    func getLocalProfile() async -> Result<UserProfile?, UserProfileError> {
        logger.debug("📱 Fetching local profile")
        return await _getLocalProfile()
    }

    func saveLocalProfile(_ profile: UserProfile) async -> Result<Void, UserProfileError> {
        logger.debug("💾 Saving profile locally")
        let result = await _saveLocalProfile(profile)

        // Notify that profile was saved
        if case .success = result {
            NotificationCenter.default.post(name: NSNotification.Name("UserProfileDidUpdate"), object: nil)
            logger.debug("📢 Posted UserProfileDidUpdate notification")
        }

        return result
    }

    func deleteLocalProfile() async -> Result<Void, UserProfileError> {
        logger.info("🗑️ Deleting local profile")
        return await _deleteLocalProfile()
    }

    // MARK: - Private @MainActor methods for SwiftData operations

    private func _getLocalProfile() async -> Result<UserProfile?, UserProfileError> {
        do {
            let profileDTOs = try await localDataSource.fetchAll()
            let profileDomain = profileDTOs.first.map { domainMapper.toDomain($0) }

            if profileDomain != nil {
                logger.debug("✅ Local profile found")
            } else {
                logger.debug("ℹ️ No local profile found")
            }

            return .success(profileDomain)

        } catch {
            logger.error("❌ Failed to fetch local profile: \(error.localizedDescription)")
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

            logger.info("✅ Profile saved to local storage")
            return .success(())

        } catch {
            logger.error("❌ Failed to save local profile: \(error.localizedDescription)")
            return .failure(.saveFailed(error.localizedDescription))
        }
    }

    private func _deleteLocalProfile() async -> Result<Void, UserProfileError> {
        do {
            try await localDataSource.clear()
            logger.info("✅ Local profile deleted")
            return .success(())

        } catch {
            logger.error("❌ Failed to delete local profile: \(error.localizedDescription)")
            return .failure(.deleteFailed(error.localizedDescription))
        }
    }
}
