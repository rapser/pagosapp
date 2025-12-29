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
    private let mapper: UserProfileMapper.Type
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "UserProfileRepositoryImpl")

    init(remoteDataSource: UserProfileRemoteDataSource, localDataSource: UserProfileLocalDataSource, mapper: UserProfileMapper.Type = UserProfileMapper.self) {
        self.remoteDataSource = remoteDataSource
        self.localDataSource = localDataSource
        self.mapper = mapper
        logger.info("✅ UserProfileRepositoryImpl initialized")
    }

    // MARK: - Remote Operations

    func fetchProfile(userId: UUID) async -> Result<UserProfileEntity, UserProfileError> {
        logger.info("📥 Fetching profile for user: \(userId)")

        do {
            guard let profileDTO = try await remoteDataSource.fetchProfile(userId: userId) else {
                logger.error("❌ Profile not found for user: \(userId)")
                return .failure(.profileNotFound)
            }

            let profileEntity = mapper.toDomain(from: profileDTO)
            logger.info("✅ Profile fetched and mapped to domain entity")
            return .success(profileEntity)

        } catch {
            logger.error("❌ Failed to fetch profile: \(error.localizedDescription)")
            return .failure(.fetchFailed(error.localizedDescription))
        }
    }

    func updateProfile(_ profile: UserProfileEntity) async -> Result<UserProfileEntity, UserProfileError> {
        logger.info("📤 Updating profile for user: \(profile.userId)")

        do {
            let profileDTO = mapper.toRemoteDTO(from: profile)
            try await remoteDataSource.updateProfile(profileDTO)

            logger.info("✅ Profile updated successfully")
            return .success(profile)

        } catch {
            logger.error("❌ Failed to update profile: \(error.localizedDescription)")
            return .failure(.updateFailed(error.localizedDescription))
        }
    }

    // MARK: - Local Operations

    func getLocalProfile() async -> Result<UserProfileEntity?, UserProfileError> {
        logger.debug("📱 Fetching local profile")
        return await _getLocalProfile()
    }

    func saveLocalProfile(_ profile: UserProfileEntity) async -> Result<Void, UserProfileError> {
        logger.debug("💾 Saving profile locally")
        return await _saveLocalProfile(profile)
    }

    func deleteLocalProfile() async -> Result<Void, UserProfileError> {
        logger.info("🗑️ Deleting local profile")
        return await _deleteLocalProfile()
    }

    // MARK: - Private @MainActor methods for SwiftData operations

    private func _getLocalProfile() async -> Result<UserProfileEntity?, UserProfileError> {
        do {
            let profiles = try await localDataSource.fetchAll()
            let profileEntity = profiles.first.map { mapper.toDomain(from: $0) }

            if profileEntity != nil {
                logger.debug("✅ Local profile found")
            } else {
                logger.debug("ℹ️ No local profile found")
            }

            return .success(profileEntity)

        } catch {
            logger.error("❌ Failed to fetch local profile: \(error.localizedDescription)")
            return .failure(.fetchFailed(error.localizedDescription))
        }
    }

    private func _saveLocalProfile(_ profile: UserProfileEntity) async -> Result<Void, UserProfileError> {
        do {
            // Delete existing profiles (single profile per user)
            let existingProfiles = try await localDataSource.fetchAll()
            if !existingProfiles.isEmpty {
                try await localDataSource.deleteAll(existingProfiles)
            }

            // Save new profile
            let profileModel = mapper.toModel(from: profile)
            try await localDataSource.save(profileModel)

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
