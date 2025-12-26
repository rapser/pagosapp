//
//  UserProfileRepositoryProtocol.swift
//  pagosApp
//
//  Created by miguel tomairo on 26/12/25.
//


import Foundation

protocol UserProfileRepositoryProtocol {
    func fetchProfile(userId: UUID) async throws -> UserProfileDTO
    func updateProfile(userId: UUID, profile: ProfileUpdateDTO) async throws
    func getLocalProfile() async throws -> UserProfileEntity?
    func saveProfile(_ profile: UserProfileEntity) async throws
    func deleteLocalProfile() async throws
}
