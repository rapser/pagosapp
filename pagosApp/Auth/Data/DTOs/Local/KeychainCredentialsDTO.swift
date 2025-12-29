//
//  KeychainCredentialsDTO.swift
//  pagosApp
//
//  Keychain credentials data transfer object
//  Clean Architecture - Data Layer
//

import Foundation

/// DTO representing credentials stored in Keychain
struct KeychainCredentialsDTO {
    let accessToken: String
    let refreshToken: String
    let userId: String

    /// Initialize with individual tokens
    init(accessToken: String, refreshToken: String, userId: String) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.userId = userId
    }

    /// Check if credentials are complete
    var isComplete: Bool {
        !accessToken.isEmpty && !refreshToken.isEmpty && !userId.isEmpty
    }
}
